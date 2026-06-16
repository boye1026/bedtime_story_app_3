"""
故事路由模块
处理故事生成、查询、收藏、删除等接口
"""

import logging
from flask import Blueprint, request, jsonify, Response, stream_with_context
from app.extensions import db
from app.models.user import User
from app.models.story import Story
from app.services.story_service import StoryService
from app.services.ai_service import AIServiceError

logger = logging.getLogger(__name__)

# 创建故事蓝图
story_bp = Blueprint("story", __name__)

# 初始化故事服务
story_service = StoryService()


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


@story_bp.route("/story/generate", methods=["POST"])
def generate_story():
    """
    生成睡前故事
    ---
    请求体:
        {
            "child_name": "小明",              // 孩子姓名（必填）
            "child_age": 5,                    // 孩子年龄
            "interests": ["恐龙", "太空"],       // 兴趣爱好
            "education_directions": ["勇敢"],    // 教育方向
            "story_style": "fairy_tale",        // 故事风格
            "stream": false                     // 是否流式响应
        }
    响应:
        {
            "code": 200,
            "message": "success",
            "data": {
                "id": 1,
                "title": "小明的星空冒险",
                "content": "从前...",
                "created_at": "2024-01-01T00:00:00"
            }
        }
    """
    # 获取当前用户
    user = _get_current_user()
    if not user:
        return _error_response("未提供用户ID，请先登录", code=401)

    # 解析请求参数
    data = request.get_json(silent=True)
    if not data:
        return _error_response("请求体不能为空")

    child_name = data.get("child_name", "").strip()
    child_age = data.get("child_age")
    interests = data.get("interests", [])
    education_directions = data.get("education_directions", [])
    story_style = data.get("story_style", "fairy_tale").strip()
    is_stream = data.get("stream", False)

    # 参数验证
    if not child_name:
        return _error_response("孩子姓名不能为空")

    if child_age is not None and (child_age < 1 or child_age > 18):
        return _error_response("孩子年龄应在1-18岁之间")

    if not isinstance(interests, list):
        return _error_response("interests 应为数组格式")

    if not isinstance(education_directions, list):
        return _error_response("education_directions 应为数组格式")

    # 构建孩子信息
    child_info = {
        "name": child_name,
        "age": child_age,
        "interests": interests,
    }

    # 流式生成
    if is_stream:
        try:
            def generate():
                """流式生成器"""
                try:
                    for chunk in story_service.generate_story_stream(
                        user=user,
                        child_info=child_info,
                        story_style=story_style,
                        directions=education_directions,
                    ):
                        yield f"data: {chunk}\n\n"
                    yield "data: [DONE]\n\n"
                except PermissionError as e:
                    yield f"data: [ERROR] {str(e)}\n\n"
                except AIServiceError as e:
                    yield f"data: [ERROR] {str(e)}\n\n"
                except Exception as e:
                    yield f"data: [ERROR] 故事生成失败\n\n"

            return Response(
                stream_with_context(generate()),
                mimetype="text/event-stream",
                headers={
                    "Cache-Control": "no-cache",
                    "X-Accel-Buffering": "no",
                }
            )
        except PermissionError as e:
            return _error_response(str(e), code=403)
        except AIServiceError as e:
            return _error_response(str(e), code=500)

    # 非流式生成
    try:
        story = story_service.generate_story(
            user=user,
            child_info=child_info,
            story_style=story_style,
            directions=education_directions,
        )
    except PermissionError as e:
        return _error_response(str(e), code=403)
    except AIServiceError as e:
        logger.error(f"AI 生成失败: {str(e)}")
        return _error_response(str(e), code=500)
    except ValueError as e:
        return _error_response(str(e))
    except Exception as e:
        logger.error(f"故事生成未知错误: {str(e)}")
        return _error_response("故事生成失败，请稍后重试", code=500)

    return _success_response(
        data=story.to_dict(),
        message="故事生成成功"
    )


@story_bp.route("/story/<int:story_id>", methods=["GET"])
def get_story(story_id):
    """
    获取故事详情
    ---
    响应:
        {
            "code": 200,
            "message": "success",
            "data": { 故事详情 }
        }
    """
    user = _get_current_user()
    if not user:
        return _error_response("未提供用户ID，请先登录", code=401)

    story = story_service.get_story(story_id)
    if not story:
        return _error_response("故事不存在", code=404)

    # 验证故事归属
    if story.user_id != user.id:
        return _error_response("无权查看该故事", code=403)

    return _success_response(data=story.to_dict())


@story_bp.route("/story/list", methods=["GET"])
def get_stories():
    """
    获取用户故事列表（分页）
    ---
    查询参数:
        page: 页码（默认1）
        per_page: 每页数量（默认20）
    响应:
        {
            "code": 200,
            "message": "success",
            "data": {
                "stories": [...],
                "total": 100,
                "page": 1,
                "per_page": 20,
                "pages": 5
            }
        }
    """
    user = _get_current_user()
    if not user:
        return _error_response("未提供用户ID，请先登录", code=401)

    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 20, type=int)

    # 参数范围限制
    page = max(1, page)
    per_page = max(1, min(100, per_page))

    result = story_service.get_user_stories(user.id, page=page, per_page=per_page)

    return _success_response(data=result)


@story_bp.route("/story/<int:story_id>/favorite", methods=["POST"])
def toggle_favorite(story_id):
    """
    收藏/取消收藏故事
    ---
    响应:
        {
            "code": 200,
            "message": "收藏成功/取消收藏成功",
            "data": { "is_favorite": true/false }
        }
    """
    user = _get_current_user()
    if not user:
        return _error_response("未提供用户ID，请先登录", code=401)

    try:
        is_favorite = story_service.toggle_favorite(story_id, user.id)
    except ValueError as e:
        return _error_response(str(e), code=404)

    message = "收藏成功" if is_favorite else "取消收藏成功"
    return _success_response(
        data={"is_favorite": is_favorite, "story_id": story_id},
        message=message
    )


@story_bp.route("/story/<int:story_id>", methods=["DELETE"])
def delete_story(story_id):
    """
    删除故事
    ---
    响应:
        {
            "code": 200,
            "message": "删除成功",
            "data": null
        }
    """
    user = _get_current_user()
    if not user:
        return _error_response("未提供用户ID，请先登录", code=401)

    try:
        story_service.delete_story(story_id, user.id)
    except ValueError as e:
        return _error_response(str(e), code=404)

    return _success_response(message="删除成功", data=None)
