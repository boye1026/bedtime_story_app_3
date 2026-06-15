"""
配置文件
使用 python-dotenv 加载 .env 环境变量配置
"""

import os
from dotenv import load_dotenv

# 加载 .env 文件中的环境变量
load_dotenv()


class Config:
    """应用基础配置"""

    # 安全密钥，用于session加密等
    SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret-key-change-in-production")

    # 数据库连接地址，默认使用SQLite
    DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///bedtime_stories.db")

    # SQLAlchemy 配置
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_DATABASE_URI = DATABASE_URL

    # ========== 通义千问 AI 配置 ==========
    # 通义千问 API 密钥
    QWEN_API_KEY = os.getenv("QWEN_API_KEY", "")

    # 通义千问 API 基础地址（兼容 OpenAI SDK 格式）
    QWEN_API_BASE = os.getenv(
        "QWEN_API_BASE",
        "https://dashscope.aliyuncs.com/compatible-mode/v1"
    )

    # 使用的模型名称
    QWEN_MODEL = os.getenv("QWEN_MODEL", "qwen-turbo")

    # AI 生成超时时间（秒）
    QWEN_TIMEOUT = int(os.getenv("QWEN_TIMEOUT", "60"))

    # ========== VIP 套餐配置 ==========
    VIP_PLANS = {
        "weekly": {
            "name": "周卡会员",
            "price": 19.9,
            "duration_days": 7,
            "description": "7天VIP会员，畅享无限故事生成"
        },
        "monthly": {
            "name": "月卡会员",
            "price": 19.9,
            "duration_days": 30,
            "description": "30天VIP会员，畅享无限故事生成"
        },
        "quarterly": {
            "name": "季卡会员",
            "price": 49.0,
            "duration_days": 90,
            "description": "90天VIP会员，畅享无限故事生成"
        }
    }

    # ========== 免费用户配置 ==========
    # 每日免费生成次数
    FREE_DAILY_COUNT = 1

    # 广告奖励额外次数
    AD_REWARD_COUNT = 1


class DevelopmentConfig(Config):
    """开发环境配置"""
    DEBUG = True


class ProductionConfig(Config):
    """生产环境配置"""
    DEBUG = False


class TestingConfig(Config):
    """测试环境配置"""
    TESTING = True
    SQLALCHEMY_DATABASE_URI = "sqlite:///:memory:"


# 配置映射表
config_map = {
    "development": DevelopmentConfig,
    "production": ProductionConfig,
    "testing": TestingConfig,
    "default": DevelopmentConfig
}


def get_config():
    """根据环境变量获取对应配置"""
    env = os.getenv("FLASK_ENV", "development")
    return config_map.get(env, DevelopmentConfig)
