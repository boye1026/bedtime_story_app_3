# 🌙 AI睡前故事生成器

[![Backend CI](https://github.com/boye1026/bedtime_story_app_3/actions/workflows/backend-ci.yml/badge.svg)](https://github.com/boye1026/bedtime_story_app_3/actions/workflows/backend-ci.yml)
[![Flutter CI](https://github.com/boye1026/bedtime_story_app_3/actions/workflows/build-apk.yml/badge.svg)](https://github.com/boye1026/bedtime_story_app_3/actions/workflows/build-apk.yml)

一款面向亲子的AI睡前故事生成应用，支持Android和iOS双平台。家长只需输入宝宝信息，即可通过云端AI生成专属睡前故事，并支持语音朗读。

## ✨ 功能特性

- 🎨 **童趣卡通UI** — 柔和色彩、大字体、星星月亮动画，适合夜间使用
- 👶 **个性化定制** — 输入孩子姓名、年龄、兴趣爱好，生成专属故事
- 🤖 **AI智能生成** — 对接通义千问API，4种故事风格（童话/冒险/温馨/启蒙）
- 🔊 **语音朗读** — 系统TTS朗读，支持播放/暂停/继续/停止
- ❤️ **收藏管理** — 本地存储收藏故事，随时重温
- 👑 **会员系统** — 周/月/季三档会员套餐，无限生成+精品故事库
- 📺 **激励广告** — 免费次数用尽后可观看广告额外解锁

## 📁 项目结构

```
bedtime_story_app/
├── mobile/          # Flutter 跨平台移动端
│   ├── lib/
│   │   ├── pages/       # 6个页面（首页/设置/故事/个人中心/收藏/会员）
│   │   ├── services/    # API/TTS/存储/广告服务
│   │   ├── models/      # 数据模型
│   │   ├── theme/       # 主题与色彩
│   │   └── widgets/     # 通用组件
│   └── pubspec.yaml
│
└── backend/         # Python Flask 后端API
    ├── app/
    │   ├── routes/        # RESTful API路由
    │   ├── services/      # 业务逻辑
    │   ├── models/        # 数据库模型
    │   └── templates/     # 故事Prompt模板（可扩展）
    ├── requirements.txt
    └── Dockerfile
```

## 🚀 快速开始

### 环境要求

- **前端**: Flutter SDK >= 3.10.0, Dart >= 3.0.0
- **后端**: Python >= 3.11
- **AI服务**: 通义千问API密钥（[阿里云百炼平台](https://bailian.console.aliyun.com/)申请）

### 后端启动

```bash
cd backend

# 1. 创建虚拟环境
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 2. 安装依赖
pip install -r requirements.txt

# 3. 配置环境变量
cp .env.example .env
# 编辑 .env，填入你的通义千问API密钥

# 4. 启动服务
python run.py
# 服务运行在 http://localhost:5000
```

### 前端启动

```bash
cd mobile

# 1. 获取依赖
flutter pub get

# 2. 生成平台目录（首次）
flutter create .

# 3. 配置API地址
# 编辑 lib/config/api_config.dart，将 baseUrl 改为你的后端地址

# 4. 运行
flutter run
```

### Docker 一键部署

```bash
# 1. 配置环境变量
cp backend/.env.example .env
# 编辑 .env 填入配置

# 2. 启动
docker-compose up -d

# 3. 查看日志
docker-compose logs -f backend
```

## 📱 页面预览

| 首页 | 信息设置 | 故事展示 | 个人中心 |
|------|----------|----------|----------|
| 星星月亮动画 + 大按钮 | 表单 + Chip选择 | 宽松排版 + 语音控制 | 会员标识 + 菜单列表 |

## 🔌 API 接口

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/auth/register` | 用户注册 |
| POST | `/api/auth/login` | 用户登录 |
| POST | `/api/story/generate` | 生成故事 |
| GET | `/api/story/<id>` | 获取故事详情 |
| GET | `/api/stories` | 故事列表 |
| GET | `/api/membership/plans` | 会员套餐 |
| POST | `/api/membership/activate` | 激活会员 |
| POST | `/api/user/ad-reward` | 广告奖励 |

## 🧩 扩展开发

### 新增故事风格模板

在 `backend/app/templates/story_prompts.py` 中：

```python
@register_template("science")
class ScienceTemplate(StoryTemplate):
    """科普风格故事模板"""
    name = "科普风"
    system_prompt = "你是一个儿童科普故事作家..."
```

### 接入广告SDK

在 `mobile/lib/services/ad_service.dart` 中实现 `showRewardedAd()` 方法，接入穿山甲/优量汇等SDK。

### 接入支付

在 `mobile/lib/pages/membership_page.dart` 中替换支付逻辑，接入微信/支付宝支付SDK。

## 📄 许可证

本项目仅供学习交流使用，商业使用请自行处理相关合规事宜。

## 🙏 致谢

- [Flutter](https://flutter.dev/) — 跨平台UI框架
- [Flask](https://flask.palletsprojects.com/) — Python Web框架
- [通义千问](https://tongyi.aliyun.com/) — AI大语言模型
