"""
Distributed Kimi-K2-Instruct int4 inference worker using DeepSpeed-MII.

Each MPI process runs the same code. MII handles tensor parallelism
split across the MPI rank. Served via a FastAPI HTTP endpoint so that
Gateway API can route requests to any pod and the internal service
load-balances across all 63 MPI replica pods.
"""

import os
import logging

import torch
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from mii import MII

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

MODEL_DIR = os.environ.get("MODEL_DIR", "/models/kimi-k2-instruct-int4")
NUM_WORKERS = int(os.environ.get("NUM_WORKERS", "63"))
INFERENCE_PORT = int(os.environ.get("INFERENCE_PORT", "8080"))

logger.info(
    "Worker starting — model=%s, port=%d, workers=%d",
    MODEL_DIR, INFERENCE_PORT, NUM_WORKERS,
)


async def lifespan(app: FastAPI):
    logger.info("Loading model from %s (int4)...", MODEL_DIR)
    MII().init_model(
        model_path=MODEL_DIR,
        model_type="inference",
        tensor_parallel_size=NUM_WORKERS,
        dtype="float16",
    )
    logger.info("Model loaded — ready to serve")


app = FastAPI(
    title="Kimi-K2-Instruct int4 Inference",
    lifespan=lifespan,
)


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/v1/completions")
async def completions(request: Request):
    try:
        body = await request.json()
    except Exception:
        return JSONResponse({"error": "invalid json"}, status_code=400)

    prompt = body.get("prompt", "")
    max_tokens = body.get("max_tokens", 2048)
    temperature = body.get("temperature", 0.1)

    try:
        result = MII().llm.generate(
            prompt=prompt,
            max_new_tokens=max_tokens,
            temperature=temperature,
        )
        return {"text": result}
    except Exception as e:
        logger.error("Generation failed: %s", e)
        return JSONResponse({"error": str(e)}, status_code=500)
