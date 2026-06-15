"""
通义千问 AI 服务模块
使用 OpenAI SDK 连接通义千问 API，提供故事生成能力
支持流式和非流式响应
"""

import logging
from openai import OpenAI, APITimeoutError, AuthenticationError, APIError

logger = logging.getLogger(__name__)


class AIService:
    """
    通义千问 AI 服务类
    封装与通义千问 API 的交互逻辑
    """

    def __init__(self, app=None):
        """
        初始化 AI 服务

        Args:
            app: Flask 应用实例（可选，用于延迟初始化）
        """
        self.client = None
        self.model = None
        self.timeout = 60

        if app is not None:
            self.init_app(app)


# 创建全局 AI 服务实例
ai_service = AIService()

    def init_app(self, app):
        """
        使用 Flask 应用配置初始化 AI 服务

        Args:
            app: Flask 应用实例
        """
        api_key = app.config.get("QWEN_API_KEY", "")
        api_base = app.config.get("QWEN_API_BASE", "https://dashscope.aliyuncs.com/compatible-mode/v1")
        self.model = app.config.get("QWEN_MODEL", "qwen-turbo")
        self.timeout = app.config.get("QWEN_TIMEOUT", 60)

        if not api_key:
            logger.warning("QWEN_API_KEY 未配置，AI 服务将无法正常工作")

        # 使用 OpenAI SDK 初始化客户端（通义千问兼容模式）
        self.client = OpenAI(
            api_key=api_key,
            base_url=api_base,
            timeout=self.timeout,
        )

        logger.info(f"AI 服务初始化完成，模型: {self.model}")

    def generate_story(self, system_prompt, user_prompt, stream=False):
        """
        调用通义千问 API 生成故事

        Args:
            system_prompt (str): 系统提示词，定义 AI 的角色和行为
            user_prompt (str): 用户提示词，包含故事生成的具体要求
            stream (bool): 是否使用流式响应，默认为 False

        Returns:
            str: 生成的故事内容（非流式模式）
            generator: 流式响应生成器（流式模式）

        Raises:
            AIServiceError: AI 服务相关错误
        """
        if self.client is None:
            raise AIServiceError("AI 服务未初始化，请检查配置")

        try:
            if stream:
                return self._generate_stream(system_prompt, user_prompt)
            else:
                return self._generate_sync(system_prompt, user_prompt)

        except APITimeoutError:
            logger.error("AI API 请求超时")
            raise AIServiceError("AI 生成超时，请稍后重试")

        except AuthenticationError:
            logger.error("AI API 密钥无效")
            raise AIServiceError("AI 服务认证失败，请检查 API 密钥配置")

        except APIError as e:
            logger.error(f"AI API 错误: {str(e)}")
            # 检查是否为内容安全拦截
            error_msg = str(e).lower()
            if "content" in error_msg and "safety" in error_msg:
                raise AIServiceError("故事内容未通过安全审核，请调整生成要求后重试")
            raise AIServiceError(f"AI 服务异常: {str(e)}")

        except Exception as e:
            logger.error(f"AI 生成未知错误: {str(e)}")
            raise AIServiceError(f"故事生成失败: {str(e)}")

    def _generate_sync(self, system_prompt, user_prompt):
        """
        非流式生成故事

        Args:
            system_prompt (str): 系统提示词
            user_prompt (str): 用户提示词

        Returns:
            str: 生成的故事文本
        """
        logger.info("开始非流式故事生成...")

        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            temperature=0.8,      # 适度的创造性
            max_tokens=2000,        # 最大生成长度
            top_p=0.9,
            stream=False,
        )

        content = response.choices[0].message.content.strip()
        logger.info(f"故事生成完成，长度: {len(content)} 字符")

        return content

    def _generate_stream(self, system_prompt, user_prompt):
        """
        流式生成故事

        Args:
            system_prompt (str): 系统提示词
            user_prompt (str): 用户提示词

        Yields:
            str: 逐段生成的故事文本
        """
        logger.info("开始流式故事生成...")

        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            temperature=0.8,
            max_tokens=2000,
            top_p=0.9,
            stream=True,
        )

        full_content = ""
        for chunk in response:
            if chunk.choices and chunk.choices[0].delta.content:
                delta = chunk.choices[0].delta.content
                full_content += delta
                yield delta

        logger.info(f"流式故事生成完成，总长度: {len(full_content)} 字符")


class AIServiceError(Exception):
    """AI 服务自定义异常"""
    pass
