from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from ..config import get_settings

settings = get_settings()
_client: AsyncIOMotorClient | None = None
_db: AsyncIOMotorDatabase | None = None


async def get_database() -> AsyncIOMotorDatabase:
    global _client, _db
    if _db is None:
        _client = AsyncIOMotorClient(settings.MONGODB_URL)
        _db = _client[settings.MONGODB_DB]
        await _db.users.create_index("email", unique=True)
        await _db.images.create_index("user_id")
    return _db


async def close_database():
    global _client, _db
    if _client:
        _client.close()
        _client = None
        _db = None
