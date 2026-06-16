# GitHub Actions 工作流说明

本项目包含以下自动化工作流：

## 📱 build-apk.yml

**功能**：自动构建 Android APK

**触发条件**：
- 推送到 `main` 分支
- 创建 `v*` 标签（如 `v1.0.0`）
- 手动触发

**输出**：
- APK 文件上传到 GitHub Artifacts
- 创建标签时自动发布到 GitHub Releases

## 🧪 backend-ci.yml

**功能**：后端代码质量检查

**触发条件**：
- 推送到 `main` 分支且修改了 `backend/` 目录
- PR 到 `main` 分支且修改了 `backend/` 目录
- 手动触发

**检查内容**：
- Python 语法检查
- Flake8 代码规范检查
- 模块导入验证

## 📲 build-ios.yml

**功能**：构建 iOS 应用

**触发条件**：
- 推送到 `main` 分支
- 创建 `v*` 标签
- 手动触发

**注意**：
- 使用 macOS runner（需要额外付费）
- 构建结果是未签名的 `.app` 文件
- 需要在本地使用 Xcode 签名后上传到 App Store

## 🚀 deploy-backend.yml

**功能**：构建并部署后端 Docker 镜像

**触发条件**：
- 推送到 `main` 分支且修改了 `backend/` 目录
- 手动触发

**需要配置的 Secrets**：
- `DOCKER_HUB_USERNAME` - Docker Hub 用户名
- `DOCKER_HUB_TOKEN` - Docker Hub 访问令牌
- `SECRET_KEY` - 应用密钥
- `QWEN_API_KEY` - 通义千问 API Key
-（可选）`SSH_HOST`, `SSH_USERNAME`, `SSH_KEY` - 服务器部署信息

## 📋 使用步骤

### 1. 首次配置 Secrets

在 GitHub 仓库的 Settings → Secrets and variables → Actions 中添加以下 Secrets：

| Secret | 说明 |
|--------|------|
| `DOCKER_HUB_USERNAME` | Docker Hub 用户名 |
| `DOCKER_HUB_TOKEN` | Docker Hub Access Token |
| `SECRET_KEY` | Flask 应用密钥 |
| `QWEN_API_KEY` | 阿里云 DashScope API Key |

### 2. 触发构建

**方式一：推送代码**
```bash
git push origin main
```

**方式二：创建版本标签**
```bash
git tag -a v1.0.0 -m "版本 1.0.0"
git push origin v1.0.0
```

**方式三：手动触发**
在 GitHub 仓库的 Actions 页面选择对应工作流，点击 "Run workflow"

### 3. 下载构建产物

构建完成后，在 Actions 页面的对应工作流中点击 "Artifacts" 下载 APK 或 IPA 文件。

## ⚡ 性能优化

- 使用 `flutter clean` 确保每次构建环境干净
- 使用 `actions/upload-artifact` 上传产物，保留 7 天
- 后端 CI 只在修改后端代码时触发
