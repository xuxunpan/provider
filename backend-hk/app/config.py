from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    APP_NAME: str = "AI Provider - HK Proxy"
    DEBUG: bool = True

    # OpenAI
    OPENAI_API_KEY: str = "sk-your-openai-api-key"
    OPENAI_BASE_URL: str = "https://api.openai.com/v1"

    # Internal API key for domestic backend to call this service
    INTERNAL_API_KEY: str = "shared-secret-key-between-services"

    # File storage for generated images
    GENERATED_DIR: str = "generated"

    class Config:
        env_file = ".env"
        extra = "allow"


@lru_cache()
def get_settings() -> Settings:
    return Settings()
