"""
会员订单模型
记录用户的VIP会员购买和激活信息
"""

from datetime import datetime
from decimal import Decimal
from app.extensions import db


class Membership(db.Model):
    """会员订单模型"""

    __tablename__ = "memberships"

    # ========== 基本字段 ==========
    id = db.Column(db.Integer, primary_key=True, autoincrement=True, comment="订单ID")
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False, index=True, comment="所属用户ID")

    # ========== 套餐信息 ==========
    plan_type = db.Column(db.String(20), nullable=False, comment="套餐类型：weekly/monthly/quarterly")
    amount = db.Column(db.Numeric(10, 2), nullable=False, comment="订单金额")

    # ========== 订单状态 ==========
    status = db.Column(db.String(20), nullable=False, default="pending",
                        comment="订单状态：pending/success/failed")

    # ========== 有效期 ==========
    start_date = db.Column(db.DateTime, nullable=True, comment="会员开始时间")
    expire_date = db.Column(db.DateTime, nullable=True, comment="会员过期时间")

    # ========== 时间戳 ==========
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False, comment="创建时间")

    def to_dict(self):
        """将会员订单对象转换为字典（用于API响应）"""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "plan_type": self.plan_type,
            "amount": float(self.amount) if self.amount else 0,
            "status": self.status,
            "start_date": self.start_date.isoformat() if self.start_date else None,
            "expire_date": self.expire_date.isoformat() if self.expire_date else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f"<Membership {self.id}: user={self.user_id} plan={self.plan_type} status={self.status}>"
