"""
认证路由模块
处理用户注册、登录、个人信息等接口
"""

import logging
from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.user import User

logger = logging.getLogger(__name__)

# 创建认证蓝图
auth_bp = Blueprint("auth", __name__)


def _success_response(data=None, message="success", code=200):
    """构建统一成功响应"""
    return jsonify({"code": code, "message": message, "data": data}), code


def _error_response(message="error", code=400, data=None):
    """构建统一错误响应"""
    return jsonify({"code": code, "message": message, "data": data}), code


@auth_bp.route("/register", methods=["POST"])
def register():
    """
    用户注册
    ---
    请求体:
        {
            "phone": "13800138000",    // 手机号（可选）
            "nickname": "小星星"        // 昵称（可选，默认"小读者"）
        }
    响应:
        {
            "code": 200,
            "message": "注册成功",
            "data": { 用户信息 }
        }
    """
    data = request.get_json(silent=True)
    if not data:
        return _error_response("请求体不能为空")

    phone = data.get("phone", "").strip()
    nickname = data.get("nickname", "小读者").strip()

    # 参数验证
    if phone and len(phone) != 11:
        return _error_response("手机号格式不正确")

    if not nickname:
        return _error_response("昵称不能为空")

    if len(nickname) > 50:
        return _error_response("昵称长度不能超过50个字符")

    # 检查手机号是否已注册
    if phone:
        existing_user = User.query.filter_by(phone=phone).first()
        if existing_user:
            return _error_response("该手机号已注册", code=409)

    # 创建用户
    user = User(phone=phone if phone else None, nickname=nickname)
    db.session.add(user)

    try:
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        logger.error(f"注册失败: {str(e)}")
        return _error_response("注册失败，请稍后重试")

    logger.info(f"新用户注册成功: {user.id} - {user.nickname}")

    return _success_response(
        data=user.to_dict(),
        message="注册成功"
    )


@auth_bp.route("/login", methods=["POST"])
def login():
    """
    用户登录
    ---
    请求体:
        {
            "phone": "13800138000"     // 手机号
        }
    响应:
        {
            "code": 200,
            "message": "登录成功",
            "data": { 用户信息 }
        }
    """
    data = request.get_json(silent=True)
    if not data:
        return _error_response("请求体不能为空")

    phone = data.get("phone", "").strip()

    # 参数验证
    if not phone:
        return _error_response("手机号不能为空")

    if len(phone) != 11:
        return _error_response("手机号格式不正确")

    # 查找用户
    user = User.query.filter_by(phone=phone).first()
    if not user:
        return _error_response("用户不存在，请先注册", code=404)

    logger.info(f"用户登录: {user.id} - {user.nickname}")

    return _success_response(
        data=user.to_dict(),
        message="登录成功"
    )


@auth_bp.route("/profile", methods=["GET"])
def get_profile():
    """
    获取用户信息
    ---
    请求头:
        X-User-ID: 用户ID
    响应:
        {
            "code": 200,
            "message": "success",
            "data": { 用户信息 }
        }
    """
    # 从请求头获取用户ID（简化版，生产环境应使用JWT等认证方式）
    user_id = request.headers.get("X-User-ID", type=int)
    if not user_id:
        return _error_response("未提供用户ID，请先登录", code=401)

    user = User.query.get(user_id)
    if not user:
        return _error_response("用户不存在", code=404)

    return _success_response(data=user.to_dict())
