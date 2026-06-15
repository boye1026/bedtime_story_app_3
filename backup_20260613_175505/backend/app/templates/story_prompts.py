"""
故事 Prompt 模板模块
定义各种风格的睡前故事生成模板，支持扩展新模板

使用方式：
    1. 继承 StoryTemplate 基类
    2. 实现 system_prompt 属性和 build_prompt 方法
    3. 调用 register_template() 注册模板
    4. 通过 get_template(style_name) 获取对应模板
"""

from abc import ABC, abstractmethod


# ========== 模板注册表 ==========
_template_registry = {}


def register_template(style_name):
    """
    模板注册装饰器
    将模板类注册到全局注册表中

    Usage:
        @register_template("fairy_tale")
        class FairyTaleTemplate(StoryTemplate):
            ...
    """
    def decorator(cls):
        _template_registry[style_name] = cls()
        return cls
    return decorator


def get_template(style_name):
    """
    根据风格名称获取对应的模板实例

    Args:
        style_name: 风格名称，如 "fairy_tale", "adventure" 等

    Returns:
        StoryTemplate: 对应的模板实例

    Raises:
        ValueError: 当风格名称不存在时抛出
    """
    template = _template_registry.get(style_name)
    if template is None:
        available = ", ".join(_template_registry.keys())
        raise ValueError(
            f"未知的故事风格: '{style_name}'，"
            f"可用风格: {available}"
        )
    return template


def get_available_styles():
    """
    获取所有可用的故事风格列表

    Returns:
        list: 风格名称列表
    """
    return list(_template_registry.keys())


class StoryTemplate(ABC):
    """
    故事模板基类
    所有故事风格模板都应继承此类并实现抽象方法
    """

    @property
    @abstractmethod
    def style_name(self):
        """风格名称（英文标识）"""
        pass

    @property
    @abstractmethod
    def style_display_name(self):
        """风格显示名称（中文）"""
        pass

    @property
    @abstractmethod
    def system_prompt(self):
        """系统提示词，定义AI的角色和基本行为规范"""
        pass

    @abstractmethod
    def build_prompt(self, child_info, directions=None):
        """
        根据孩子信息和教育方向构建完整的故事生成提示词

        Args:
            child_info (dict): 孩子信息，包含:
                - name (str): 孩子姓名
                - age (int): 孩子年龄
                - interests (list): 兴趣爱好列表
            directions (list, optional): 教育方向列表

        Returns:
            str: 完整的故事生成提示词
        """
        pass

    def _build_child_description(self, child_info):
        """
        构建孩子描述信息

        Args:
            child_info (dict): 孩子信息字典

        Returns:
            str: 格式化的孩子描述
        """
        parts = []
        name = child_info.get("name", "小朋友")
        age = child_info.get("age")
        interests = child_info.get("interests", [])

        parts.append(f"孩子叫{name}")
        if age:
            parts.append(f"今年{age}岁")
        if interests:
            interests_str = "、".join(interests)
            parts.append(f"喜欢{interests_str}")

        return "，".join(parts) + "。"

    def _build_direction_description(self, directions):
        """
        构建教育方向描述

        Args:
            directions (list): 教育方向列表

        Returns:
            str: 格式化的教育方向描述
        """
        if not directions:
            return ""

        return "请在故事中融入以下教育方向：" + "、".join(directions) + "。"


# ========== 通用内容要求（所有模板共享） ==========
COMMON_REQUIREMENTS = (
    "\n\n【内容要求】\n"
    "1. 篇幅控制在300-500字，适合睡前短阅读\n"
    "2. 绝对不包含任何恐怖、暴力、惊悚元素\n"
    "3. 故事结尾必须温馨、积极，给孩子带来安全感\n"
    "4. 语言简洁优美，适合儿童理解\n"
    "5. 请为故事起一个吸引人的标题，格式为「标题：xxx」\n"
    "6. 故事内容要适合作为睡前故事，节奏舒缓，有助于入睡"
)


# ========== 具体模板实现 ==========

@register_template("fairy_tale")
class FairyTaleTemplate(StoryTemplate):
    """童话风格模板"""

    @property
    def style_name(self):
        return "fairy_tale"

    @property
    def style_display_name(self):
        return "童话风"

    @property
    def system_prompt(self):
        return (
            "你是一位专业的儿童睡前故事作家，擅长创作充满想象力的童话故事。"
            "你的故事充满魔法、奇幻元素和美好的寓意，"
            "能够激发孩子的想象力和创造力。"
        )

    def build_prompt(self, child_info, directions=None):
        child_desc = self._build_child_description(child_info)
        direction_desc = self._build_direction_description(directions)

        prompt = (
            f"请以童话风格写一个睡前故事。\n\n"
            f"【读者信息】\n{child_desc}\n\n"
            f"{direction_desc}\n"
            f"【风格要求】\n"
            f"故事中可以包含会说话的动物、神奇的魔法森林、"
            f"善良的精灵等童话元素，营造梦幻般的氛围。"
            f"{COMMON_REQUIREMENTS}"
        )
        return prompt


@register_template("adventure")
class AdventureTemplate(StoryTemplate):
    """冒险风格模板"""

    @property
    def style_name(self):
        return "adventure"

    @property
    def style_display_name(self):
        return "冒险风"

    @property
    def system_prompt(self):
        return (
            "你是一位专业的儿童睡前故事作家，擅长创作充满探索精神的冒险故事。"
            "你的故事充满奇遇和发现，能够培养孩子的勇气和好奇心。"
        )

    def build_prompt(self, child_info, directions=None):
        child_desc = self._build_child_description(child_info)
        direction_desc = self._build_direction_description(directions)

        prompt = (
            f"请以冒险风格写一个睡前故事。\n\n"
            f"【读者信息】\n{child_desc}\n\n"
            f"{direction_desc}\n"
            f"【风格要求】\n"
            f"故事中可以包含有趣的探险旅程、神秘的宝藏、"
            f"勇敢的小伙伴等冒险元素，但要注意冒险过程安全有趣，不吓人。"
            f"{COMMON_REQUIREMENTS}"
        )
        return prompt


@register_template("warm")
class WarmTemplate(StoryTemplate):
    """温馨风格模板"""

    @property
    def style_name(self):
        return "warm"

    @property
    def style_display_name(self):
        return "温馨风"

    @property
    def system_prompt(self):
        return (
            "你是一位专业的儿童睡前故事作家，擅长创作温暖治愈的睡前故事。"
            "你的故事充满爱与关怀，能够让孩子在温馨的氛围中安然入睡。"
        )

    def build_prompt(self, child_info, directions=None):
        child_desc = self._build_child_description(child_info)
        direction_desc = self._build_direction_description(directions)

        prompt = (
            f"请以温馨风格写一个睡前故事。\n\n"
            f"【读者信息】\n{child_desc}\n\n"
            f"{direction_desc}\n"
            f"【风格要求】\n"
            f"故事中可以包含家人之间的温暖互动、"
            f"小动物的友情、季节的变换等温馨元素，"
            f"营造温暖、安心、舒适的睡前氛围。"
            f"{COMMON_REQUIREMENTS}"
        )
        return prompt


@register_template("educational")
class EducationalTemplate(StoryTemplate):
    """启蒙教育风格模板"""

    @property
    def style_name(self):
        return "educational"

    @property
    def style_display_name(self):
        return "启蒙风"

    @property
    def system_prompt(self):
        return (
            "你是一位专业的儿童睡前故事作家，擅长创作寓教于乐的启蒙故事。"
            "你的故事能够在有趣的情节中自然融入知识启蒙，"
            "帮助孩子认识世界、学习新知识。"
        )

    def build_prompt(self, child_info, directions=None):
        child_desc = self._build_child_description(child_info)
        direction_desc = self._build_direction_description(directions)

        prompt = (
            f"请以启蒙教育风格写一个睡前故事。\n\n"
            f"【读者信息】\n{child_desc}\n\n"
            f"{direction_desc}\n"
            f"【风格要求】\n"
            f"故事中可以融入自然知识、生活常识、"
            f"数学启蒙、科学探索等教育元素，"
            f"让孩子在有趣的故事中自然地学到知识。"
            f"{COMMON_REQUIREMENTS}"
        )
        return prompt


# ========== 扩展示例（预留位置） ==========
# 如需新增模板，按以下格式编写并注册即可：
#
# @register_template("sci_fi")
# class SciFiTemplate(StoryTemplate):
#     """科幻风格模板"""
#
#     @property
#     def style_name(self):
#         return "sci_fi"
#
#     @property
#     def style_display_name(self):
#         return "科幻风"
#
#     @property
#     def system_prompt(self):
#         return "你是一位擅长创作儿童科幻故事的作家..."
#
#     def build_prompt(self, child_info, directions=None):
#         ...
