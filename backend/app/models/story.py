"""
故事模型
存储AI生成的睡前故事内容及相关元数据
"""

from datetime import datetime
from app.extensions import db


class Story(db.Model):
    """故事模型"""

    __tablename__ = "stories"

    # ========== 基本字段 ==========
    id = db.Column(db.Integer, primary_key=True, autoincrement=True, comment="故事ID")
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False, index=True, comment="所属用户ID")
    title = db.Column(db.String(200), nullable=False, comment="故事标题")
    content = db.Column(db.Text, nullable=False, comment="故事内容")

    # ========== 孩子信息（生成时记录） ==========
    child_name = db.Column(db.String(50), nullable=True, comment="孩子姓名")
    child_age = db.Column(db.Integer, nullable=True, comment="孩子年龄")
    interests = db.Column(db.JSON, nullable=True, comment="孩子兴趣爱好（JSON数组）")
    education_directions = db.Column(db.JSON, nullable=True, comment="教育方向（JSON数组）")

    # ========== 故事属性 ==========
    story_style = db.Column(db.String(30), nullable=False, default="fairy_tale",
                            comment="故事风格：fairy_tale/adventure/warm/educational")
    is_premium = db.Column(db.Boolean, default=False, nullable=False, comment="是否为VIP专属故事")
    is_favorite = db.Column(db.Boolean, default=False, nullable=False, comment="是否已收藏")

    # ========== 时间戳 ==========
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False, comment="创建时间")

    def to_dict(self):
        """将故事对象转换为字典（用于API响应）"""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "title": self.title,
            "content": self.content,
            "child_name": self.child_name,
            "child_age": self.child_age,
            "interests": self.interests,
            "education_directions": self.education_directions,
            "story_style": self.story_style,
            "is_premium": self.is_premium,
            "is_favorite": self.is_favorite,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f"<Story {self.id}: {self.title}>"
