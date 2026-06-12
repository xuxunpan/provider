from fastapi import APIRouter, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from motor.motor_asyncio import AsyncIOMotorDatabase

from ..models.user import UserRegister, UserLogin
from ..services.auth import register_user, login_user
from ..services.database import get_database
from ..utils.security import decode_access_token

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])
security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> dict:
    payload = decode_access_token(credentials.credentials)
    if payload is None:
        from fastapi import HTTPException, status
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")

    user = await db.users.find_one({"_id": payload["sub"]})
    if not user:
        from fastapi import HTTPException, status
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")

    return {"id": str(user["_id"]), "email": user["email"]}


@router.post("/register")
async def register(data: UserRegister, db: AsyncIOMotorDatabase = Depends(get_database)):
    return await register_user(db, data)


@router.post("/login")
async def login(data: UserLogin, db: AsyncIOMotorDatabase = Depends(get_database)):
    return await login_user(db, data.email, data.password)


@router.get("/me")
async def get_me(current_user: dict = Depends(get_current_user)):
    return {"user": current_user}
