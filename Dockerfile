# Base Image
FROM --platform=linux/arm64 arm64v8/debian:bookworm-slim AS runner


# 인자 추가
ARG APP_BINARY=./artifacts/tootodo-be
ARG APP=/usr/src/app

# 환경 변수 설정
ENV TZ=Etc/UTC \
    APP_USER=appuser

# 런타임 의존성 설치
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        tzdata \
    && rm -rf /var/lib/apt/lists/* 

# 실행 사용자 및 디렉토리 설정
RUN groupadd $APP_USER \
    && useradd -g $APP_USER $APP_USER \
    && mkdir -p ${APP}

# 바이너리 복사 (외부에서 제공된 아티팩트 사용)
COPY --chown=$APP_USER:$APP_USER ${APP_BINARY} $APP/tootodo-be


# 실행 사용자 및 작업 디렉토리 설정
USER $APP_USER
WORKDIR ${APP}

# 기본 실행 명령어 및 포트 설정
ENTRYPOINT ["./tootodo-be"]
EXPOSE 8000
