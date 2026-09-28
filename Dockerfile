# ═══════════════════════════════════════════════════════════════════
# CP2 — Containerization (production-ready)
#
#   Stage 1 `builder`: cài dependency vào /install (có thể cần compiler)
#   Stage 2 `runtime`: chỉ copy kết quả đã cài + mã nguồn, chạy bằng user thường
#
# Build:  docker build -t day12-agent:prod .
# ═══════════════════════════════════════════════════════════════════

# ---------- Stage 1: builder ----------
FROM python:3.11-slim AS builder

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /build

# Copy requirements TRƯỚC để layer pip install được cache khi chỉ sửa code
COPY requirements.txt .
RUN pip install --prefix=/install -r requirements.txt


# ---------- Stage 2: runtime ----------
FROM python:3.11-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000

# User thường, UID cố định 10001 — không chạy bằng root
RUN groupadd --gid 10001 appuser \
    && useradd --uid 10001 --gid appuser --create-home --shell /usr/sbin/nologin appuser

# Chỉ lấy thư viện đã cài từ builder, không mang theo cache/compiler
COPY --from=builder /install /usr/local

WORKDIR /app

# Mã nguồn copy SAU dependency
COPY --chown=appuser:appuser app ./app
COPY --chown=appuser:appuser utils ./utils

USER appuser

EXPOSE 8000

# Gọi /health bằng Python có sẵn trong image (slim không có curl)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import os, urllib.request; urllib.request.urlopen('http://127.0.0.1:' + os.environ.get('PORT', '8000') + '/health', timeout=4).read()" || exit 1

# Dạng shell (sh -c) để ${PORT:-8000} được nội suy lúc chạy; exec để uvicorn là PID 1 và nhận SIGTERM trực tiếp
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
