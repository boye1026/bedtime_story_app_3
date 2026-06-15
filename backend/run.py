"""
应用启动入口
创建 Flask 应用并启动开发服务器
"""

from app import create_app

# 创建应用实例
app = create_app()

if __name__ == "__main__":
    # 开发模式运行，监听所有网络接口
    app.run(
        host="0.0.0.0",
        port=5000,
        debug=True,
    )
