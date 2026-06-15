# ===== AI睡前故事生成器 后端Docker镜像 =====
FROM python:3.11-slim

# 设置工作目录
WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖文件并安装
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY . .

# 创建instance目录（用于SQLite数据库）
RUN mkdir -p instance

# 暴露端口
EXPOSE 5000

# 使用gunicorn运行
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "run:app"]
