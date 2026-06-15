"""
会员路由模块
处理VIP套餐查询、会员激活、状态查询等接口
"""

import logging
from flask import Blueprint, request, jsonify
from app.models.user import User
from app.services.membership_service import MembershipService

logger = logging.getLogger(__name__)

# 创建会员蓝图
membership_bp = Blueprint("membership", __name__)

# 初始化会员服务
membership_service = MembershipService()


def _success_response(data=None, message="success", code=200):
    """构建统一成功响应"""
    return jsonify({"code": code, "message": message, "data": data}), code


def _error_response(message="error", code=400, data=None):
    """构建统一错误响应"""
    return jsonify({"code": code, "message": message, "data": data}), code


def _get_current_user():
    """
    从请求头获取当前用户（简化版）
    生产环境应使用JWT等认证中间件

    Returns:
        User: 用户对象，如果未认证返回 None
    """
    user_id = request.headers.get("X-User-ID", type=int)
    if not user_id:
        return None
    return User.query.get(user_id)


@membership_bp.route("/plans", methods=["GET"])
def get_plans():
    """
    获取VIP套餐列表
    ---
    响应:
        {
            "code": 200,
            "message": "success",
            "data": [
                {
                    "plan_type": "weekly",
                    "name": "周卡会员",
                    "price": 19.9,
                    "duration_days": 7,
                    "description": "7天VIP会员..."
                },
                ...
            ]
        }
    """
    plans = membership_service.get_plans()
    return _success_response(data=plans)


@membership_bp.route("/activate", methods=["POST"])
def activate_membership():
    """
    激活VIP会员
    ---
    请求体:
        {
            "plan_type": "monthly"     // 套餐类型：weekly/monthly/quarterly
        }
    响应:
        {
            "code": 200,
            "message": "会员激活成功",
            "data": { 订单信息 }
        }
    """
    user = _get_current_user()
    if not user:
        return _error_response("未提供用户ID，请先登录", code=401)

    data = request.get_json(silent=True)
    if not data:
        return _error_response("请求体不能为空")

    plan_type = data.get("plan_type", "").strip()

    if not plan_type:
        return _error_response("请选择套餐类型")

    try:
        membership = membership_service.activate_membership(user, plan_type)
    except ValueError as e:
        return _error_response(str(e))

    return _success_response(
        data=membership.to_dict(),
        message="会员激活成功"
    )


@membership_bp.route("/status", methods=["GET"])
def get_membership_status():
    """
    查询会员状态
    ---
    响应:
        {
            "code": 200,
            "message": "success",
            "data": {
                "is_vip": true,
                "is_active": true,
                "vip_expire_date": "2024-12-31T23:59:59",
                "remaining_days": 30,
                "latest_plan": "monthly"
            }
        }
    """
    user = _get_current_user()
    if not user:
        return _error_response("未提供用户ID，请先登录", code=401)

    status = membership_service.check_vip_status(user)
    return _success_response(data=status)
