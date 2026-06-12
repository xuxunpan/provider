import os
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from ..config import get_settings
from ..models.image import ImageRecord
from ..services.database import get_database
from ..services.openai_proxy import generate_image
from .auth import get_current_user

router = APIRouter(prefix="/api/v1/images", tags=["images"])
settings = get_settings()


@router.post("/generate")
async def generate(
    prompt: str = Form(...),
    image: UploadFile | None = File(None),
    current_user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    user_id = current_user["id"]

    # Save uploaded image locally
    original_image_url = None
    if image and image.filename:
        os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
        ext = os.path.splitext(image.filename)[1] or ".png"
        filename = f"{uuid.uuid4()}{ext}"
        filepath = os.path.join(settings.UPLOAD_DIR, filename)
        content = await image.read()
        with open(filepath, "wb") as f:
            f.write(content)
        original_image_url = f"/uploads/{filename}"

    # Create record
    record = ImageRecord(
        user_id=user_id,
        original_image_url=original_image_url,
        prompt=prompt,
        status="processing",
    )
    result = await db.images.insert_one(record.model_dump(by_alias=True, exclude={"id"}))
    record_id = str(result.inserted_id)

    try:
        # Call HK backend
        if image:
            await image.seek(0)  # reset file pointer for re-read
            result_data = await generate_image(prompt=prompt, image_file=image)
        else:
            result_data = await generate_image(prompt=prompt)

        generated_url = result_data.get("generated_image_url")

        # Update record
        await db.images.update_one(
            {"_id": result.inserted_id},
            {
                "$set": {
                    "status": "completed",
                    "generated_image_url": generated_url,
                    "updated_at": datetime.now(timezone.utc),
                }
            },
        )

        return {
            "id": record_id,
            "status": "completed",
            "original_image_url": original_image_url,
            "prompt": prompt,
            "generated_image_url": generated_url,
        }

    except Exception as e:
        await db.images.update_one(
            {"_id": result.inserted_id},
            {
                "$set": {
                    "status": "failed",
                    "error_message": str(e),
                    "updated_at": datetime.now(timezone.utc),
                }
            },
        )
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))


@router.get("/history")
async def get_history(
    current_user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database),
    skip: int = 0,
    limit: int = 20,
):
    cursor = (
        db.images.find({"user_id": current_user["id"]})
        .sort("created_at", -1)
        .skip(skip)
        .limit(limit)
    )
    records = []
    async for doc in cursor:
        doc["_id"] = str(doc["_id"])
        records.append(doc)
    return {"items": records, "total": await db.images.count_documents({"user_id": current_user["id"]})}
