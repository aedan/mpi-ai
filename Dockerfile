FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    libnuma1 \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    deepspeed-mii \
    torch==2.4.1 \
    transformers \
    accelerate \
    sentencepiece \
    tokenizers \
    uvicorn[standard] \
    fastapi \
    requests

ENV MODEL_DIR=/models/kimi-k2-instruct-int4
ENV NUM_WORKERS=63
ENV MPI_HOST_FILE=/opt/mpi-operator/hostfile
ENV INFERENCE_PORT=8080

COPY worker.py /worker.py

CMD ["python", "/worker.py"]
