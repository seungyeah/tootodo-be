# Builder Stage
FROM rust:slim-bookworm AS builder
ENV SQLX_OFFLINE=true
WORKDIR /app

# Install dependencies and cross-compilers
RUN apt-get update \
    && apt-get install -y \
        gcc-aarch64-linux-gnu \
        libc6-dev-arm64-cross \
        pkg-config \
        curl \
    && rustup target add aarch64-unknown-linux-gnu 

ENV CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc


# Only copy over the Cargo manifest files
COPY ./Cargo.toml ./Cargo.lock ./

# This trick will cache the dependencies as a separate layer
RUN mkdir src/ \
    && echo "fn main() {}" > src/main.rs \
    && cargo build --release --target aarch64-unknown-linux-gnu\
    && rm -f target/aarch64-unknown-linux-gnu/release/deps/tootodo_be*


# Copy source files and build the application
COPY . .
RUN cargo build --release --target aarch64-unknown-linux-gnu --locked


# Production Stage
FROM debian:bookworm-slim AS runner
ARG APP=/usr/src/app
ENV TZ=Etc/UTC APP_USER=appuser

# Install only the runtime dependencies
RUN apt-get update \
    && apt-get install -y ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd $APP_USER \
    && useradd -g $APP_USER $APP_USER \
    && mkdir -p ${APP}

# Copy the built binary from the builder stage
COPY --from=builder /app/target/aarch64-unknown-linux-gnu/release/tootodo-be ${APP}/tootodo-be

# Ensure the user owns the application files
RUN chown -R $APP_USER:$APP_USER ${APP}

USER $APP_USER
WORKDIR ${APP}

ENTRYPOINT ["./tootodo-be"]
EXPOSE 8000