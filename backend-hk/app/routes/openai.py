import os
import uuid
import base64
import httpx
from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Header, Depends, status
from openai import AsyncOpenAI

from ..config import get_settings

router = APIRouter(prefix="/api/v1/openai", tags=["openai"])
settings = get_settings()


async def verify_api_key(x_api_key: str = Header(..., alias="X-API-Key")):
    if x_api_key != settings.INTERNAL_API_KEY:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="API Key 无效")
    return x_api_key


def get_openai_client() -> AsyncOpenAI:
    return AsyncOpenAI(
        api_key=settings.OPENAI_API_KEY,
        base_url=settings.OPENAI_BASE_URL,
    )


@router.post("/generate-image")
async def generate_image(
    prompt: str = Form(...),
    image: UploadFile | None = File(None),
    _: str = Depends(verify_api_key),
):
    """
    Generate image using OpenAI.
    Flow:
    1. If an image is provided, send it to GPT-4o Vision to get a detailed description
    2. Combine with user prompt to create a DALL-E prompt
    3. Call DALL-E 3 to generate the image
    4. Download and save the generated image locally
    """
    client = get_openai_client()
    dalle_prompt = prompt

    # If reference image provided, use GPT-4o Vision to describe it
    if image and image.filename:
        image_bytes = await image.read()
        image_b64 = base64.b64encode(image_bytes).decode("utf-8")

        mime_type = image.content_type or "image/png"
        if mime_type not in ("image/png", "image/jpeg", "image/webp", "image/gif"):
            raise HTTPException(status_code=400, detail="不支持的图片格式")

        vision_response = await client.chat.completions.create(
            model=settings.OPENAI_VISION_MODEL,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": "Describe this image in detail. Focus on the visual elements, style, composition, colors, and subject matter. Provide a comprehensive description suitable for an image generation prompt.",
                        },
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:{mime_type};base64,{image_b64}",
                                "detail": "high",
                            },
                        },
                    ],
                }
            ],
            max_tokens=500,
        )
        image_description = vision_response.choices[0].message.content

        # Combine user prompt with image description
        dalle_prompt = (
            f"Reference image description: {image_description}\n\n"
            f"User's request: {prompt}\n\n"
            f"Create a new image based on the reference image style and composition, "
            f"incorporating the user's requested changes."
        )

    # Generate image with DALL-E 3
    response = await client.images.generate(
        model=settings.OPENAI_IMAGE_MODEL,
        prompt=dalle_prompt[:4000],  # DALL-E prompt limit
        size="1024x1024",
        quality="standard",
        n=1,
    )

    image_url = response.data[0].url

    # Download generated image and save locally
    os.makedirs(settings.GENERATED_DIR, exist_ok=True)
    filename = f"{uuid.uuid4()}.png"
    filepath = os.path.join(settings.GENERATED_DIR, filename)

    async with httpx.AsyncClient() as http_client:
        img_response = await http_client.get(image_url)
        with open(filepath, "wb") as f:
            f.write(img_response.content)

    return {
        "generated_image_url": f"/generated/{filename}",
        "dalle_prompt_used": dalle_prompt[:200],
        "openai_url": image_url,
    }
