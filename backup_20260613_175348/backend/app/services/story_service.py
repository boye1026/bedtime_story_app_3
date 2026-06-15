"""
故事生成业务逻辑模块
处理故事生成的完整流程：权限检查 -> 模板选择 -> AI生成 -> 保存 -> 扣减次数
"""

import logging
import re
from app.extensions import db
from app.models.story import Story
from app.models.user import User
from app.services.ai_service import AIService, AIServiceError, ai_service
from app.templates.story_prompts import get_template

logger = logging.getLogger(__name__)


class StoryService:
    """
    故事服务类
    封装故事生成、查询、删除等业务逻辑
    """

    def __init__(self, ai_service=None):
        """
        初始化故事服务

        Args:
            ai_service: AI 服务实例，如果为 None 则创建新实例
        """
        self.ai_service = ai_service

    def generate_story(self, user, child_info, story_style="fairy_tale",
                       directions=None, is_premium=False):
        """
        生成一个睡前故事（完整流程）

        流程:
        1. 检查用户生成权限（免费次数或VIP）
        2. 获取对应风格的故事模板
        3. 构建提示词
        4. 调用 AI 服务生成故事
        5. 解析标题和内容
        6. 保存故事到数据库
        7. 扣减免费次数（非VIP用户）

        Args:
            user (User): 用户对象
            child_info (dict): 孩子信息，包含 name, age, interests
            story_style (str): 故事风格，默认 "fairy_tale"
            directions (list, optional): 教育方向列表
            is_premium (bool): 是否为高级故事，默认 False

        Returns:
            Story: 创建的故事对象

        Raises:
            PermissionError: 用户无权生成故事（免费次数用完且非VIP）
            AIServiceError: AI 生成失败
            ValueError: 参数错误
        """
        # ===== 1. 参数验证 =====
        if not child_info or not child_info.get("name"):
            raise ValueError("孩子姓名不能为空")

        # ===== 2. 检查用户生成权限 =====
        if not user.can_generate():
            raise PermissionError(
                "今日免费次数已用完，请开通VIP会员或明日再试"
            )

        # ===== 3. 获取故事模板 =====
        try:
            template = get_template(story_style)
        except ValueError as e:
            raise ValueError(str(e))

        # ===== 4. 构建提示词 =====
        system_prompt = template.system_prompt
        user_prompt = template.build_prompt(child_info, directions)

        logger.info(f"用户 {user.id} 请求生成故事，风格: {story_style}")

        # ===== 5. 调用 AI 服务生成 =====
        try:
            raw_content = self.ai_service.generate_story(
                system_prompt=system_prompt,
                user_prompt=user_prompt,
                stream=False
            )
        except AIServiceError:
            raise

        # ===== 6. 解析标题和内容 =====
        title, content = self._parse_story_content(raw_content, child_info.get("name"))

        # ===== 7. 创建并保存故事 =====
        story = Story(
            user_id=user.id,
            title=title,
            content=content,
            child_name=child_info.get("name"),
            child_age=child_info.get("age"),
            interests=child_info.get("interests"),
            education_directions=directions,
            story_style=story_style,
            is_premium=is_premium,
        )

        db.session.add(story)

        # ===== 8. 扣减免费次数（非VIP用户） =====
        if not user.is_vip:
            user.consume_free_count()

        db.session.commit()

        logger.info(f"故事生成成功，ID: {story.id}, 标题: {story.title}")
        return story

    def generate_story_stream(self, user, child_info, story_style="fairy_tale",
                              directions=None, is_premium=False):
        """
        流式生成睡前故事

        与 generate_story 类似，但返回流式生成器。
        注意：流式模式下，故事会在生成完成后自动保存到数据库。

        Args:
            user (User): 用户对象
            child_info (dict): 孩子信息
            story_style (str): 故事风格
            directions (list, optional): 教育方向列表
            is_premium (bool): 是否为高级故事

        Yields:
            str: 逐段生成的故事文本

        Raises:
            PermissionError: 用户无权生成故事
            AIServiceError: AI 生成失败
        """
        # 权限检查
        if not child_info or not child_info.get("name"):
            raise ValueError("孩子姓名不能为空")

        if not user.can_generate():
            raise PermissionError("今日免费次数已用完，请开通VIP会员或明日再试")

        # 获取模板
        template = get_template(story_style)
        system_prompt = template.system_prompt
        user_prompt = template.build_prompt(child_info, directions)

        logger.info(f"用户 {user.id} 请求流式生成故事，风格: {story_style}")

        # 流式生成
        full_content = ""
        try:
            for chunk in self.ai_service.generate_story(
                system_prompt=system_prompt,
                user_prompt=user_prompt,
                stream=True
            ):
                full_content += chunk
                yield chunk
        except AIServiceError:
            raise

        # 生成完成后保存
        title, content = self._parse_story_content(full_content, child_info.get("name"))

        story = Story(
            user_id=user.id,
            title=title,
            content=content,
            child_name=child_info.get("name"),
            child_age=child_info.get("age"),
            interests=child_info.get("interests"),
            education_directions=directions,
            story_style=story_style,
            is_premium=is_premium,
        )

        db.session.add(story)

        if not user.is_vip:
            user.consume_free_count()

        db.session.commit()
        logger.info(f"流式故事生成完成并保存，ID: {story.id}")

    def get_story(self, story_id):
        """
        获取故事详情

        Args:
            story_id (int): 故事ID

        Returns:
            Story: 故事对象，如果不存在返回 None
        """
        return Story.query.get(story_id)

    def get_user_stories(self, user_id, page=1, per_page=20):
        """
        获取用户的故事列表（分页）

        Args:
            user_id (int): 用户ID
            page (int): 页码，默认1
            per_page (int): 每页数量，默认20

        Returns:
            dict: 包含故事列表和分页信息
        """
        pagination = (
            Story.query
            .filter_by(user_id=user_id)
            .order_by(Story.created_at.desc())
            .paginate(page=page, per_page=per_page, error_out=False)
        )

        return {
            "stories": [story.to_dict() for story in pagination.items],
            "total": pagination.total,
            "page": pagination.page,
            "per_page": pagination.per_page,
            "pages": pagination.pages,
        }

    def toggle_favorite(self, story_id, user_id):
        """
        切换故事的收藏状态

        Args:
            story_id (int): 故事ID
            user_id (int): 用户ID

        Returns:
            bool: 切换后的收藏状态

        Raises:
            ValueError: 故事不存在或不属于该用户
        """
        story = Story.query.filter_by(id=story_id, user_id=user_id).first()
        if not story:
            raise ValueError("故事不存在或无权操作")

        story.is_favorite = not story.is_favorite
        db.session.commit()

        logger.info(f"故事 {story_id} 收藏状态切换为: {story.is_favorite}")
        return story.is_favorite

    def delete_story(self, story_id, user_id):
        """
        删除故事

        Args:
            story_id (int): 故事ID
            user_id (int): 用户ID

        Raises:
            ValueError: 故事不存在或不属于该用户
        """
        story = Story.query.filter_by(id=story_id, user_id=user_id).first()
        if not story:
            raise ValueError("故事不存在或无权操作")

        db.session.delete(story)
        db.session.commit()

        logger.info(f"故事 {story_id} 已删除")

    def _parse_story_content(self, raw_content, child_name):
        """
        解析 AI 生成的原始内容，提取标题和正文

        AI 可能返回的格式：
        - 「标题：xxx」\\n\\n正文内容
        - 标题：xxx\\n\\n正文内容
        - 【标题】xxx\\n\\n正文内容
        - 直接返回正文（无明确标题）

        Args:
            raw_content (str): AI 生成的原始文本
            child_name (str): 孩子姓名（用于生成默认标题）

        Returns:
            tuple: (title, content) 标题和正文
        """
        if not raw_content:
            return f"给{child_name}的睡前故事", "今天的故事暂时走丢了，明天再来听吧~"

        # 尝试匹配各种标题格式
        title_patterns = [
            r"「标题[：:]\s*(.+?)」",       # 「标题：xxx」
            r"【标题[：:]\s*(.+?)】",        # 【标题：xxx】
            r"标题[：:]\s*(.+?)[\n\r]",     # 标题：xxx\n
            r"#\s*(.+?)[\n\r]",             # # xxx\n
        ]

        title = None
        content = raw_content.strip()

        for pattern in title_patterns:
            match = re.search(pattern, raw_content, re.MULTILINE)
            if match:
                title = match.group(1).strip()
                # 移除标题行，保留正文
                content = re.sub(pattern, "", raw_content, count=1, flags=re.MULTILINE).strip()
                # 移除标题后的空行
                content = re.sub(r"^[\s\n\r]+", "", content)
                break

        # 如果没有提取到标题，使用默认标题
        if not title:
            # 尝试取第一行作为标题
            first_line = content.split("\n")[0].strip()
            if len(first_line) <= 30 and not first_line.startswith("第"):
                title = first_line
                content = "\n".join(content.split("\n")[1:]).strip()
            else:
                title = f"给{child_name}的睡前故事"

        # 确保内容不为空
        if not content:
            content = raw_content.strip()

        return title, content
