import httpx
from fastapi import UploadFile, HTTPException, status

from ..config import get_settings

settings = get_settings()


async def generate_image(
    prompt: str,
    image_file: UploadFile | None = None,
    token: str | None = None,
) -> dict:
    """
    Forward the image generation request to the Hong Kong backend.
    The HK backend will use OpenAI GPT-4o + DALL-E to generate images.
    """
    url = f"{settings.HK_BACKEND_URL}/api/v1/openai/generate-image"

    async with httpx.AsyncClient(timeout=120.0) as client:
        if image_file:
            files = {"image": (image_file.filename, await image_file.read(), image_file.content_type)}
            data = {"prompt": prompt}
            headers = {"X-API-Key": settings.HK_BACKEND_API_KEY}
            if token:
                headers["Authorization"] = f"Bearer {token}"

            response = await client.post(url, files=files, data=data, headers=headers)
        else:
            headers = {
                "X-API-Key": settings.HK_BACKEND_API_KEY,
                "Content-Type": "application/json",
            }
            if token:
                headers["Authorization"] = f"Bearer {token}"
            response = await client.post(url, json={"prompt": prompt}, headers=headers)

        if response.status_code != 200:
            detail = response.text
            try:
                detail = response.json().get("detail", response.text)
            except Exception:
                pass
            raise HTTPException(status_code=response.status_code, detail=f"HK 后端错误: {detail}")

        return response.json()
