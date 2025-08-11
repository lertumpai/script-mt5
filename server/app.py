import os
import asyncio
from datetime import datetime, timedelta
from typing import Optional, Literal, Dict, Any

from fastapi import FastAPI, HTTPException, Depends, Header
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from dotenv import load_dotenv

# IQ Option API (community lib)
try:
    from iqoptionapi.stable_api import IQ_Option  # type: ignore
except Exception as e:  # pragma: no cover
    IQ_Option = None  # deferred import error surfaced at runtime


load_dotenv()


class Settings(BaseModel):
    iq_username: str = Field(default_factory=lambda: os.getenv("IQ_USERNAME", ""))
    iq_password: str = Field(default_factory=lambda: os.getenv("IQ_PASSWORD", ""))
    api_key: str = Field(default_factory=lambda: os.getenv("API_KEY", "change-me"))
    connect_on_startup: bool = Field(default_factory=lambda: os.getenv("CONNECT_ON_STARTUP", "true").lower() in ("1", "true", "yes"))


settings = Settings()
app = FastAPI(
    title="IQOption API Server (MT2-like)",
    version="0.1.0",
    description="REST API to place trades, check balances, and track results on IQ Option (community API)",
    openapi_tags=[
        {"name": "Auth", "description": "Authentication and session management"},
        {"name": "Trading", "description": "Place orders and check results"},
        {"name": "Accounts", "description": "Account info and balances"},
        {"name": "Diagnostics", "description": "Health and utility endpoints"},
    ],
)


# In-memory session
class IQSession:
    def __init__(self) -> None:
        self.client: Optional[IQ_Option] = None
        self.connected: bool = False
        self.last_login_at: Optional[datetime] = None

    async def connect(self, username: str, password: str) -> None:
        if IQ_Option is None:
            raise HTTPException(status_code=500, detail="iqoptionapi not installed correctly")
        loop = asyncio.get_event_loop()
        def _login() -> bool:
            client = IQ_Option(username, password)
            client.connect()
            # community lib uses check_connect() to indicate session state
            if not client.check_connect():
                return False
            self.client = client
            return True
        ok = await loop.run_in_executor(None, _login)
        if not ok:
            raise HTTPException(status_code=401, detail="IQ Option login failed")
        self.connected = True
        self.last_login_at = datetime.utcnow()

    def ensure_connected(self) -> None:
        if not self.connected or self.client is None:
            raise HTTPException(status_code=401, detail="Not connected to IQ Option")


iq = IQSession()


async def auth_guard(x_api_key: Optional[str] = Header(default=None)) -> None:
    if settings.api_key and x_api_key != settings.api_key:
        raise HTTPException(status_code=401, detail="Invalid API key")


class LoginRequest(BaseModel):
    username: Optional[str] = None
    password: Optional[str] = None

class LoginResponse(BaseModel):
    status: Literal["ok"]
    connected: bool
    logged_at: Optional[str]


@app.post("/login", tags=["Auth"], summary="Login to IQ Option", response_model=LoginResponse)
async def login(body: LoginRequest) -> JSONResponse:
    username = body.username or settings.iq_username
    password = body.password or settings.iq_password
    if not username or not password:
        raise HTTPException(status_code=400, detail="username/password required")
    await iq.connect(username, password)
    return JSONResponse({"status": "ok", "connected": iq.connected, "logged_at": iq.last_login_at.isoformat() if iq.last_login_at else None})


class PlaceOrderRequest(BaseModel):
    symbol: str = Field(examples=["EURUSD"])
    direction: Literal["CALL", "PUT"]
    amount: float = Field(gt=0)
    expiry_minutes: int = Field(default=1, ge=1, le=60)
    instrument: Literal["binary", "digital"] = Field(default="binary")

class TradeResponse(BaseModel):
    status: Literal["placed"]
    instrument: Literal["binary", "digital"]
    order_id: Any


@app.post("/trade", dependencies=[Depends(auth_guard)], tags=["Trading"], summary="Place a trade", response_model=TradeResponse)
async def trade(req: PlaceOrderRequest) -> JSONResponse:
    iq.ensure_connected()
    assert iq.client is not None
    client = iq.client

    # IQ Option expects lower-case pair with a suffix for timeframe, e.g., EURUSD for turbo/binary
    asset = req.symbol.upper()
    direction = "call" if req.direction == "CALL" else "put"

    # Community lib blocking call — run in executor
    loop = asyncio.get_event_loop()

    def _place_binary() -> dict:
        # open_binary_option returns (success, order_id)
        ok, order_id = client.buy(req.amount, asset, direction, req.expiry_minutes)
        return {"ok": bool(ok), "order_id": order_id}

    def _place_digital() -> dict:
        # digital: client.buy_digital_spot(asset, amount, direction, duration)
        order_id = client.buy_digital_spot(asset, req.amount, direction, req.expiry_minutes)
        return {"ok": order_id is not None and order_id != -1, "order_id": order_id}

    result = await loop.run_in_executor(None, _place_binary if req.instrument == "binary" else _place_digital)
    if not result.get("ok"):
        raise HTTPException(status_code=502, detail=f"Failed to place {req.instrument} order")
    return JSONResponse({"status": "placed", "instrument": req.instrument, **result})


class CheckResultRequest(BaseModel):
    order_id: str
    instrument: Literal["binary", "digital"] = Field(default="binary")

class TradeResultResponse(BaseModel):
    done: bool
    win: float


@app.post("/trade/result", dependencies=[Depends(auth_guard)], tags=["Trading"], summary="Check trade result", response_model=TradeResultResponse)
async def trade_result(req: CheckResultRequest) -> JSONResponse:
    iq.ensure_connected()
    assert iq.client is not None
    client = iq.client
    loop = asyncio.get_event_loop()

    def _check_binary() -> dict:
        # returns: (done, win)
        done, win = client.check_win_v2(req.order_id)
        return {"done": bool(done), "win": float(win)}

    def _check_digital() -> dict:
        # digital check
        done, win = client.check_win_digital_v2(req.order_id)
        return {"done": bool(done), "win": float(win)}

    result = await loop.run_in_executor(None, _check_binary if req.instrument == "binary" else _check_digital)
    return JSONResponse(result)


class BalanceResponse(BaseModel):
    balance: float
    account_type: str


@app.get("/balance", dependencies=[Depends(auth_guard)], tags=["Accounts"], summary="Get account balance", response_model=BalanceResponse)
async def balance() -> JSONResponse:
    iq.ensure_connected()
    assert iq.client is not None
    client = iq.client
    loop = asyncio.get_event_loop()

    def _balance() -> dict:
        bal = client.get_balance()
        acc_type = client.get_balance_mode()
        return {"balance": float(bal), "account_type": acc_type}

    data = await loop.run_in_executor(None, _balance)
    return JSONResponse(data)


@app.get("/profile", dependencies=[Depends(auth_guard)], tags=["Accounts"], summary="Get profile")
async def profile() -> JSONResponse:
    iq.ensure_connected()
    assert iq.client is not None
    client = iq.client
    loop = asyncio.get_event_loop()

    def _profile() -> dict:
        return client.get_profile_ansyc() if hasattr(client, "get_profile_ansyc") else client.get_profile()

    data = await loop.run_in_executor(None, _profile)
    return JSONResponse(data)


class OpenOrdersResponse(BaseModel):
    digital: Any
    binary: Any


@app.get("/orders/open", dependencies=[Depends(auth_guard)], tags=["Trading"], summary="List open orders", response_model=OpenOrdersResponse)
async def open_orders() -> JSONResponse:
    iq.ensure_connected()
    assert iq.client is not None
    client = iq.client
    loop = asyncio.get_event_loop()

    def _fetch() -> dict:
        out: dict = {"digital": [], "binary": []}
        try:
            digital = client.get_positions("digital-option")
            out["digital"] = digital or []
        except Exception:
            out["digital"] = []
        try:
            binary = client.get_positions("binary-option")
            out["binary"] = binary or []
        except Exception:
            out["binary"] = []
        return out

    data = await loop.run_in_executor(None, _fetch)
    return JSONResponse(data)


@app.on_event("startup")
async def on_startup() -> None:
    if settings.connect_on_startup and settings.iq_username and settings.iq_password:
        try:
            await iq.connect(settings.iq_username, settings.iq_password)
        except Exception:
            # Lazy connect via /login
            pass


class HealthResponse(BaseModel):
    status: Literal["ok"]
    connected: bool


@app.get("/healthz", tags=["Diagnostics"], summary="Health check", response_model=HealthResponse)
async def healthz() -> JSONResponse:
    return JSONResponse({"status": "ok", "connected": iq.connected})


def create_app() -> FastAPI:
    return app


