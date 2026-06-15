"""
Flask 扩展初始化模块
集中管理所有 Flask 扩展实例，避免循环导入
"""

from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS

# SQLAlchemy 数据库实例
db = SQLAlchemy()

# CORS 跨域实例（在应用工厂中初始化）
cors = CORS()
