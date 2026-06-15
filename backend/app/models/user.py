"""
用户模型
管理用户基本信息、VIP状态和免费生成次数
"""

from datetime import date, datetime
from app.extensions import db


class User(db.Model):
    """用户模型"""

    __tablename__ = "users"

    # ========== 基本字段 ==========
    id = db.Column(db.Integer, primary_key=True, autoincrement=True, comment="用户ID")
    phone = db.Column(db.String(20), unique=True, nullable=True, comment="手机号（可选）")
    nickname = db.Column(db.String(50), nullable=False, default="小读者", comment="用户昵称")
    avatar_url = db.Column(db.String(500), nullable=True, comment="头像URL")

    # ========== VIP 相关字段 ==========
    is_vip = db.Column(db.Boolean, default=False, nullable=False, comment="是否为VIP会员")
    vip_expire_date = db.Column(db.DateTime, nullable=True, comment="VIP过期时间")

    # ========== 免费生成次数 ==========
    free_count_today = db.Column(db.Integer, default=1, nullable=False, comment="今日剩余免费生成次数")
    last_generate_date = db.Column(db.Date, nullable=True, comment="上次生成故事的日期")

    # ========== 时间戳 ==========
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False, comment="创建时间")
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False, comment="更新时间")

    # ========== 关系 ==========
    stories = db.relationship("Story", backref="user", lazy="dynamic")  # 用户的故事列表
    memberships = db.relationship("Membership", backref="user", lazy="dynamic")  # 用户的会员订单列表

    def can_generate(self):
        """
        判断用户今日是否还能免费生成故事

        Returns:
            bool: True 表示可以生成，False 表示不能
        """
        today = date.today()

        # 如果是VIP用户且未过期，可以无限生成
        if self.is_vip and self.vip_expire_date:
            if self.vip_expire_date.date() >= today:
                return True
            else:
                # VIP已过期，更新状态
                self.is_vip = False
                self.vip_expire_date = None

        # 检查是否是新的一天，如果是则重置免费次数
        if self.last_generate_date != today:
            self.free_count_today = 1
            self.last_generate_date = today
            db.session.commit()

        # 检查免费次数
        return self.free_count_today > 0

    def consume_free_count(self):
        """
        消耗一次免费生成次数

        Returns:
            bool: True 表示消耗成功，False 表示次数不足
        """
        if not self.can_generate():
            return False

        today = date.today()
        if self.last_generate_date != today:
            self.free_count_today = 1
            self.last_generate_date = today

        self.free_count_today -= 1
        db.session.commit()
        return True

    def add_free_count(self, count=1):
        """
        增加免费生成次数（例如广告奖励）

        Args:
            count: 增加的次数，默认为1
        """
        today = date.today()

        # 如果不是今天，先重置
        if self.last_generate_date != today:
            self.free_count_today = 0
            self.last_generate_date = today

        self.free_count_today += count
        db.session.commit()

    def to_dict(self):
        """将用户对象转换为字典（用于API响应）"""
        return {
            "id": self.id,
            "phone": self.phone,
            "nickname": self.nickname,
            "avatar_url": self.avatar_url,
            "is_vip": self.is_vip,
            "vip_expire_date": self.vip_expire_date.isoformat() if self.vip_expire_date else None,
            "free_count_today": self.free_count_today,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f"<User {self.id}: {self.nickname}>"
