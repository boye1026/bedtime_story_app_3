"""
故事提示词模板模块
为不同的故事风格提供系统提示词和用户提示词构建器
"""

class StoryTemplate:
    """故事模板基类"""
    
    def __init__(self, style_name, system_prompt):
        self.style_name = style_name
        self.system_prompt = system_prompt
    
    def build_prompt(self, child_info, directions=None):
        """构建用户提示词"""
        name = child_info.get('name', '宝宝')
        age = child_info.get('age', '?')
        interests = child_info.get('interests', [])
        interests_text = '、'.join(interests) if interests else '探索世界'
        
        return f"""
请为{name}小朋友（{age}岁）创作一个{self.style_name}睡前故事。

故事要求：
1. 主角是{name}
2. 故事长度：800-1200字
3. 融入兴趣爱好：{interests_text}
4. 语言生动，每段不超过4句话
5. 结局温暖积极，传递正能量

请开始创作：
"""


# 定义各种故事风格的模板
TEMPLATES = {
    'fairy_tale': StoryTemplate(
        '童话风',
        """你是一位温柔的故事讲述者，擅长创作充满魔法和奇迹的童话故事。
故事要温馨、梦幻，语言优美，适合睡前聆听。
每段话后可以加一个小星星或月亮的表情符号。"""
    ),
    'adventure': StoryTemplate(
        '冒险风',
        """你是一位勇敢的探险家，擅长创作充满冒险和探索精神的故事。
故事要有趣、刺激但不恐怖，鼓励小朋友勇敢面对挑战。
情节要简单明了，结局要成功和成长。"""
    ),
    'warm': StoryTemplate(
        '温馨风',
        """你是一位温暖的母亲，擅长创作充满爱和安全感的故事。
故事要温柔、舒缓，强调亲情、友情和家的温暖。
语言要轻柔，像摇篮曲一样安抚小朋友入睡。"""
    ),
    'educational': StoryTemplate(
        '启蒙风',
        """你是一位耐心的老师，擅长创作寓教于乐的启蒙故事。
将知识（如数字、颜色、动物、礼貌等）自然地融入故事中。
不说教，通过有趣的情节让小朋友学到东西。"""
    ),
}


def get_template(style):
    """获取指定风格的故事模板"""
    if style not in TEMPLATES:
        raise ValueError(f"未知的故事风格: {style}，可用风格: {list(TEMPLATES.keys())}")
    return TEMPLATES[style]
