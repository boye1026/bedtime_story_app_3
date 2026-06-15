"""
Flask 应用工厂模块
使用工厂模式创建 Flask 应用实例，便于测试和配置切换
"""

from flask import Flask
from config import get_config
from app.extensions import db, cors


def create_app(config_class=None):
    """
    创建并配置 Flask 应用

    Args:
        config_class: 配置类，如果为 None 则自动根据环境变量选择

    Returns:
        Flask: 配置好的 Flask 应用实例
    """
    app = Flask(__name__)

    # 加载配置
    if config_class is None:
        config_class = get_config()
    app.config.from_object(config_class)

    # 初始化扩展
    db.init_app(app)
    cors.init_app(app, resources={r"/api/*": {"origins": "*"}})

    # 注册蓝图（路由模块）
    from app.routes.auth import auth_bp
    from app.routes.story import story_bp
    from app.routes.membership import membership_bp
    from app.routes.user import user_bp

    app.register_blueprint(auth_bp, url_prefix="/api/auth")
    app.register_blueprint(story_bp, url_prefix="/api")
    app.register_blueprint(membership_bp, url_prefix="/api/membership")
    app.register_blueprint(user_bp, url_prefix="/api/user")

    # 创建数据库表（如果不存在）
    with app.app_context():
        from app.models import user, story, membership  # noqa: F401 确保模型被导入
        db.create_all()

    # 初始化 AI 服务
    from app.services.ai_service import ai_service
    ai_service.init_app(app)

    # 注册错误处理
    _register_error_handlers(app)

    return app


def _register_error_handlers(app):
    """注册全局错误处理器，统一 JSON 响应格式"""

    @app.errorhandler(400)
    def bad_request(error):
        return {"code": 400, "message": "请求参数错误", "data": None}, 400

    @app.errorhandler(404)
    def not_found(error):
        return {"code": 404, "message": "资源不存在", "data": None}, 404

    @app.errorhandler(500)
    def internal_error(error):
        return {"code": 500, "message": "服务器内部错误", "data": None}, 500
