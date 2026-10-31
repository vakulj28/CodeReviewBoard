# Start from Astral's official uv image, which already has uv + Python 3.12.
# --platform=linux/arm64 forces the ARM64 architecture AgentCore Runtime requires,
# regardless of whether your own Mac is ARM or Intel.
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim
# All following commands run inside /app in the image.
WORKDIR /app

# Copy ONLY the dependency manifests first. Docker caches each layer, so as long
# as these two files don't change, it won't re-download packages on every build.
COPY pyproject.toml uv.lock ./

# Install the locked dependencies into the image. --no-dev skips pytest/ruff
# (not needed at runtime); --no-install-project because our pyproject is package=false.
RUN uv sync --locked --no-dev --no-install-project

# Now copy the application code. (Separate layer, so a code change doesn't bust
# the dependency cache above.)
COPY board/ ./board/

# Document that the service listens on 8080 (the port AgentCore talks to).
EXPOSE 8080

# The command the container runs on start: launch the Phase-3 Runtime server.
CMD ["uv", "run", "--no-dev", "python", "-m", "board.runtime"]