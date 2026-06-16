"""
用户路由模块
处理免费次数查询、广告奖励等接口
"""

import logging
from flask import Blueprint, request, jsonify, current_app
from app.models.user import User
from app.extensions import db

logger = logging.getLogger(__name__)

# 创建用户蓝图
user_bp = Blueprint("user", __name__)


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


@user_bp.route("/free-count", methods=["GET"])
def get_free_count():
    """
    获取今日剩余免费生成次数
    ---
    响应:
        {
            "code": 200,
            "message": "success",
            "data": {
                "free_count_today": 1,
                "is_vip": false,
                "can_generate": true
            }
        }
    """
    user = _get_current_user()
    if not user:
        return _error_response("未提供用户ID，请先登录", code=401)

    # 调用 can_generate() 会自动处理跨天重置
    can_generate = user.can_generate()

    return _success_response(data={
        "free_count_today": user.free_count_today,
        "is_vip": user.is_vip,
        "can_generate": can_generate,
    })


@user_bp.route("/info", methods=["GET"])
def get_user_info():
    """
    获取用户信息和VIP状态
    ---
    响应:
        {
            "code": 200,
            "message": "success",
            "data": {
                "id": 1,
                "nickname": "小读者",
                "is_vip": false,
                "remaining_free_count": 1,
                "vip_expire_date": null
            }
        }
    """
    user = _get_current_user()
    if not user:
        return _error_response("未提供用户ID，请先登录", code=401)

    # 调用 can_generate 自动处理跨天重置
    user.can_generate()

    return _success_response(data={
        "id": user.id,
        "nickname": user.nickname,
        "avatar_url": user.avatar_url,
        "is_vip": user.is_vip,
        "remaining_free_count": user.free_count_today,
        "vip_expire_date": user.vip_expire_date.isoformat() if user.vip_expire_date else None,
    })


@user_bp.route("/ad-reward", methods=["POST"])
def ad_reward():
    """
    广告奖励 - 观看广告后增加免费生成次数
    ---
    请求体:
        {
            "ad_type": "rewarded_video"    // 广告类型（预留字段）
        }
    响应:
        {
            "code": 200,
            "message": "奖励领取成功",
            "data": {
                "free_count_today": 2,
                "reward_count": 1
            }
        }
    """
    user = _get_current_user()
    if not user:
        return _error_response("未提供用户ID，请先登录", code=401)

    data = request.get_json(silent=True) or {}

    # 获取广告奖励配置
    reward_count = current_app.config.get("AD_REWARD_COUNT", 1)

    # 增加免费次数
    user.add_free_count(count=reward_count)

    logger.info(f"用户 {user.id} 领取广告奖励，增加 {reward_count} 次免费次数")

    return _success_response(
        data={
            "free_count_today": user.free_count_today,
            "reward_count": reward_count,
        },
        message="奖励领取成功"
    )
