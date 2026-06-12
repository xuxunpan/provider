import os
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

from .config import get_settings
from .routes import openai

settings = get_settings()

app = FastAPI(
    title=settings.APP_NAME,
    version="1.0.0",
)

os.makedirs(settings.GENERATED_DIR, exist_ok=True)
app.mount("/generated", StaticFiles(directory=settings.GENERATED_DIR), name="generated")

app.include_router(openai.router)


@app.get("/api/health")
async def health():
    return {"status": "ok", "service": "hk-proxy-backend"}
