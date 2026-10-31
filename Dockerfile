FROM ubuntu:24.04 AS web-build

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git unzip xz-utils libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*
RUN curl --fail --location --retry 3 \
    https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.35.6-stable.tar.xz \
    -o /tmp/flutter.tar.xz \
    && tar --no-same-owner -xf /tmp/flutter.tar.xz -C /opt \
    && rm /tmp/flutter.tar.xz \
    && git config --global --add safe.directory /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}"
WORKDIR /build
COPY pubspec.yaml pubspec.lock ./
COPY lib ./lib
COPY web ./web
COPY assets ./assets
RUN flutter pub get --enforce-lockfile \
    && flutter build web --release --no-pub --dart-define=API_BASE_URL=

FROM python:3.13-slim AS runtime
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    WEB_DIST_DIR=/app/web_dist
WORKDIR /app/backend
COPY backend/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt \
    && useradd --create-home --uid 10001 aivycheck
COPY backend/app ./app
COPY backend/migrations ./migrations
COPY backend/alembic.ini backend/start_cloud.py ./
COPY --from=web-build /build/build/web /app/web_dist
USER aivycheck
EXPOSE 8000
CMD ["python", "start_cloud.py"]
