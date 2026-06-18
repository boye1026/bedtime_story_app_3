"""
认证路由模块
处理用户注册、登录、个人信息等接口
"""

import logging
import random
import time
from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.user import User

logger = logging.getLogger(__name__)

# 创建认证蓝图
auth_bp = Blueprint("auth", __name__)

# 验证码缓存（生产环境应使用Redis）
# 格式: {phone: {"code": "123456", "expire_time": timestamp}}
_sms_code_cache = {}

# 验证码有效期（秒）
SMS_CODE_EXPIRE_SECONDS = 300  # 5分钟

# 测试验证码（开发环境使用）
TEST_SMS_CODE = "123456"


def _success_response(data=None, message="success", code=200):
    """构建统一成功响应"""
    return jsonify({"code": code, "message": message, "data": data}), code


def _error_response(message="error", code=400, data=None):
    """构建统一错误响应"""
    return jsonify({"code": code, "message": message, "data": data}), code


def _generate_sms_code():
    """生成6位数字验证码"""
    return str(random.randint(100000, 999999))


def _send_sms_code_mock(phone, code):
    """模拟发送短信验证码（生产环境应接入短信服务商）"""
    # 这里是模拟发送，实际生产环境需要接入阿里云、腾讯云等短信服务
    logger.info(f"[模拟短信] 发送验证码到 {phone}: {code}")
    print(f"\n========== 短信验证码 ==========")
    print(f"手机号: {phone}")
    print(f"验证码: {code}")
    print(f"有效期: {SMS_CODE_EXPIRE_SECONDS}秒")
    print(f"================================\n")
    return True


@auth_bp.route("/send_sms_code", methods=["POST"])
def send_sms_code():
    """
    发送短信验证码
    ---
    请求体:
        {
            "phone": "13800138000"     // 手机号
        }
    响应:
        {
            "code": 200,
            "message": "验证码已发送",
            "data": null
        }
    """
    data = request.get_json(silent=True)
    if not data:
        return _error_response("请求体不能为空")

    phone = data.get("phone", "").strip()

    # 参数验证
    if not phone:
        return _error_response("手机号不能为空")

    if len(phone) != 11 or not phone.startswith("1"):
        return _error_response("手机号格式不正确")

    # 检查发送频率限制（同一手机号60秒内只能发送一次）
    cached = _sms_code_cache.get(phone)
    if cached and time.time() - cached.get("send_time", 0) < 60:
        remaining = int(60 - (time.time() - cached.get("send_time", 0)))
        return _error_response(f"验证码已发送，请{remaining}秒后再试", code=429)

    # 生成验证码
    # 开发环境使用固定验证码123456，方便测试
    import os
    if os.getenv("FLASK_ENV", "development") == "development":
        code = TEST_SMS_CODE
    else:
        code = _generate_sms_code()

    # 存储验证码
    _sms_code_cache[phone] = {
        "code": code,
        "expire_time": time.time() + SMS_CODE_EXPIRE_SECONDS,
        "send_time": time.time()
    }

    # 发送验证码（模拟）
    _send_sms_code_mock(phone, code)

    logger.info(f"验证码发送成功: {phone}")

    return _success_response(message="验证码已发送，有效期5分钟")


@auth_bp.route("/verify_sms_code", methods=["POST"])
def verify_sms_code():
    """
    验证短信验证码并登录/注册
    ---
    请求体:
        {
            "phone": "13800138000",    // 手机号
            "code": "123456"           // 验证码
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
    code = data.get("code", "").strip()

    # 参数验证
    if not phone:
        return _error_response("手机号不能为空")

    if len(phone) != 11 or not phone.startswith("1"):
        return _error_response("手机号格式不正确")

    if not code:
        return _error_response("验证码不能为空")

    if len(code) != 6:
        return _error_response("验证码格式不正确")

    # 检查验证码
    cached = _sms_code_cache.get(phone)
    if not cached:
        return _error_response("验证码未发送或已过期，请重新获取")

    if time.time() > cached.get("expire_time", 0):
        # 清除过期验证码
        _sms_code_cache.pop(phone, None)
        return _error_response("验证码已过期，请重新获取")

    if code != cached.get("code"):
        return _error_response("验证码错误")

    # 验证成功，清除验证码
    _sms_code_cache.pop(phone, None)

    # 查找或创建用户
    user = User.query.filter_by(phone=phone).first()
    if not user:
        # 自动注册新用户
        user = User(phone=phone, nickname="小读者")
        db.session.add(user)
        try:
            db.session.commit()
            logger.info(f"新用户自动注册: {user.id} - {phone}")
        except Exception as e:
            db.session.rollback()
            logger.error(f"自动注册失败: {str(e)}")
            return _error_response("登录失败，请稍后重试")
    else:
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
