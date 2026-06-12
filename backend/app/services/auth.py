from fastapi import HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from ..models.user import UserRegister, UserModel
from ..utils.security import hash_password, verify_password, create_access_token
from .database import get_database


async def register_user(db: AsyncIOMotorDatabase, data: UserRegister) -> dict:
    existing = await db.users.find_one({"email": data.email})
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")

    user = UserModel(
        email=data.email,
        hashed_password=hash_password(data.password),
    )
    result = await db.users.insert_one(user.model_dump(by_alias=True, exclude={"id"}))
    created = await db.users.find_one({"_id": result.inserted_id})

    token = create_access_token({"sub": str(created["_id"]), "email": created["email"]})
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {"id": str(created["_id"]), "email": created["email"]},
    }


async def login_user(db: AsyncIOMotorDatabase, email: str, password: str) -> dict:
    user = await db.users.find_one({"email": email})
    if not user or not verify_password(password, user["hashed_password"]):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")

    if not user.get("is_active", True):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is disabled")

    token = create_access_token({"sub": str(user["_id"]), "email": user["email"]})
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {"id": str(user["_id"]), "email": user["email"]},
    }
