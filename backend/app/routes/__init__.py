"""
路由包
导出所有蓝图
"""

from app.routes.auth import auth_bp
from app.routes.story import story_bp
from app.routes.membership import membership_bp
from app.routes.user import user_bp

__all__ = ["auth_bp", "story_bp", "membership_bp", "user_bp"]
