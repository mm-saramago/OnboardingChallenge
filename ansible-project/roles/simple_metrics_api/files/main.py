from fastapi import FastAPI, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from datetime import datetime
import time

app = FastAPI(title="Simple Time Metrics API", version="1.0.0")

# Simple authentication
security = HTTPBearer()
VALID_TOKENS = {"grafana-token": "grafana"}

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Simple token verification"""
    token = credentials.credentials
    if token not in VALID_TOKENS:
        raise HTTPException(status_code=401, detail="Invalid token")
    return VALID_TOKENS[token]

@app.get("/metrics")
async def get_metrics(user: str = Depends(verify_token)):
    """Get current time metrics - now requires authentication"""
    now = datetime.now()
    return {
        "timestamp_iso": now.isoformat(),
        "timestamp_unix": int(time.time()),
        "timestamp_readable": now.strftime("%Y-%m-%d %H:%M:%S"),
        "authenticated_user": user
    }

@app.get("/health")
async def health_check():
    """Public health endpoint"""
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)