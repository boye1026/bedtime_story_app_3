"""
会员业务逻辑模块
处理VIP会员的激活、状态查询、免费次数重置等业务
"""

import logging
from datetime import datetime, timedelta, date
from decimal import Decimal

from flask import current_app
from app.extensions import db
from app.models.user import User
from app.models.membership import Membership

logger = logging.getLogger(__name__)


class MembershipService:
    """
    会员服务类
    封装VIP会员相关的业务逻辑
    """

    def __init__(self):
        """初始化会员服务"""
        pass

    def get_plans(self):
        """
        获取所有可用的VIP套餐列表

        Returns:
            list: 套餐信息列表，每个元素包含套餐详情
        """
        plans_config = current_app.config.get("VIP_PLANS", {})

        plans = []
        for plan_type, plan_info in plans_config.items():
            plans.append({
                "plan_type": plan_type,
                "name": plan_info["name"],
                "price": plan_info["price"],
                "duration_days": plan_info["duration_days"],
                "description": plan_info["description"],
            })

        return plans

    def activate_membership(self, user, plan_type):
        """
        激活VIP会员

        流程:
        1. 验证套餐类型是否有效
        2. 计算会员有效期（支持续期叠加）
        3. 创建会员订单记录
        4. 更新用户VIP状态

        Args:
            user (User): 用户对象
            plan_type (str): 套餐类型（weekly/monthly/quarterly）

        Returns:
            Membership: 创建的会员订单对象

        Raises:
            ValueError: 套餐类型无效
        """
        plans_config = current_app.config.get("VIP_PLANS", {})

        # ===== 1. 验证套餐类型 =====
        if plan_type not in plans_config:
            available = ", ".join(plans_config.keys())
            raise ValueError(f"无效的套餐类型: '{plan_type}'，可用套餐: {available}")

        plan_info = plans_config[plan_type]
        amount = Decimal(str(plan_info["price"]))
        duration_days = plan_info["duration_days"]

        # ===== 2. 计算有效期（支持续期叠加） =====
        now = datetime.utcnow()

        if user.is_vip and user.vip_expire_date and user.vip_expire_date > now:
            # VIP 未过期，在原过期时间上叠加
            start_date = user.vip_expire_date
            expire_date = start_date + timedelta(days=duration_days)
        else:
            # 新开通或已过期，从当前时间开始
            start_date = now
            expire_date = now + timedelta(days=duration_days)

        # ===== 3. 创建会员订单 =====
        membership = Membership(
            user_id=user.id,
            plan_type=plan_type,
            amount=amount,
            status="success",
            start_date=start_date,
            expire_date=expire_date,
        )

        db.session.add(membership)

        # ===== 4. 更新用户VIP状态 =====
        user.is_vip = True
        user.vip_expire_date = expire_date

        db.session.commit()

        logger.info(
            f"用户 {user.id} 激活 {plan_type} 会员，"
            f"有效期至 {expire_date.strftime('%Y-%m-%d %H:%M:%S')}"
        )

        return membership

    def check_vip_status(self, user):
        """
        查询用户的VIP会员状态

        Args:
            user (User): 用户对象

        Returns:
            dict: 包含VIP状态信息的字典
        """
        now = datetime.utcnow()

        # 检查VIP是否已过期
        is_active = False
        if user.is_vip and user.vip_expire_date:
            if user.vip_expire_date > now:
                is_active = True
            else:
                # VIP已过期，自动更新状态
                user.is_vip = False
                user.vip_expire_date = None
                db.session.commit()
                logger.info(f"用户 {user.id} 的VIP已过期，状态已更新")

        # 获取最近的会员订单
        latest_membership = (
            Membership.query
            .filter_by(user_id=user.id, status="success")
            .order_by(Membership.created_at.desc())
            .first()
        )

        return {
            "is_vip": is_active,
            "is_active": is_active,
            "vip_expire_date": user.vip_expire_date.isoformat() if user.vip_expire_date and is_active else None,
            "remaining_days": (user.vip_expire_date - now).days if is_active and user.vip_expire_date else 0,
            "latest_plan": latest_membership.plan_type if latest_membership else None,
        }

    def reset_daily_free_count(self):
        """
        重置所有用户的每日免费生成次数
        通常由定时任务调用（如每天凌晨0点执行）

        Returns:
            int: 被重置的用户数量
        """
        today = date.today()

        # 查找需要重置的用户（上次生成日期不是今天的）
        users_to_reset = (
            User.query
            .filter(
                (User.last_generate_date != today) | (User.last_generate_date.is_(None))
            )
            .all()
        )

        free_count = current_app.config.get("FREE_DAILY_COUNT", 1)

        for user in users_to_reset:
            if user.last_generate_date != today:
                user.free_count_today = free_count
                user.last_generate_date = today

        db.session.commit()

        logger.info(f"已重置 {len(users_to_reset)} 个用户的每日免费次数")
        return len(users_to_reset)

    def get_user_memberships(self, user_id, page=1, per_page=20):
        """
        获取用户的会员订单历史

        Args:
            user_id (int): 用户ID
            page (int): 页码
            per_page (int): 每页数量

        Returns:
            dict: 包含订单列表和分页信息
        """
        pagination = (
            Membership.query
            .filter_by(user_id=user_id)
            .order_by(Membership.created_at.desc())
            .paginate(page=page, per_page=per_page, error_out=False)
        )

        return {
            "memberships": [m.to_dict() for m in pagination.items],
            "total": pagination.total,
            "page": pagination.page,
            "per_page": pagination.per_page,
            "pages": pagination.pages,
        }
