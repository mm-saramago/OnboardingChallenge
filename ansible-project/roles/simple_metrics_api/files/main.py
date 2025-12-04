#!/usr/bin/env python3
"""
Simple Time Metrics API
FastAPI application that exposes current time via /metrics endpoint
"""

from fastapi import FastAPI
from datetime import datetime
import time

app = FastAPI(title="Simple Time Metrics API", version="1.0.0")

@app.get("/metrics")
async def get_metrics():
    """Get current time metrics"""
    now = datetime.now()
    return {
        "timestamp_iso": now.isoformat(),
        "timestamp_unix": int(time.time()),
        "timestamp_readable": now.strftime("%Y-%m-%d %H:%M:%S")
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)