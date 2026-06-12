from datetime import datetime, timezone
from typing import Optional
from bson import ObjectId
from pydantic import BaseModel, Field

from .user import PyObjectId


class ImageRecord(BaseModel):
    id: Optional[PyObjectId] = Field(alias="_id", default=None)
    user_id: str
    original_image_url: Optional[str] = None
    prompt: str
    generated_image_url: Optional[str] = None
    status: str = "pending"  # pending, processing, completed, failed
    error_message: Optional[str] = None
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    model_config = {"arbitrary_types_allowed": True, "populate_by_name": True}


class ImageGenerateRequest(BaseModel):
    prompt: str
