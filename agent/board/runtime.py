"""
Phase 3 - the AgentCore Runtime adapter (the "front door").

This does NOT review code. It wraps the Phase-2 board in the tiny HTTP
contract that Amazon Bedrock AgentCore Runtime expects, so the cloud can
call our agent the same way we call run_board() locally.

The contract AgentCore requires:
  - the server listens on 0.0.0.0:8080
  - GET  /ping         -> health check   (BedrockAgentCoreApp answers this for free)
  - POST /invocations  -> do the work    (our @app.entrypoint function below)

Run it locally (serves on port 8080, so give it your Bedrock creds):
    AWS_PROFILE=chatbot AWS_REGION=eu-west-1 uv run python -m board.runtime
"""

from bedrock_agentcore.runtime import BedrockAgentCoreApp

from board.board import run_board

# Create the app. This object IS the web server. It already knows how to
# answer GET /ping; we just need to tell it what POST /invocations should do.
app = BedrockAgentCoreApp()


@app.entrypoint
def invoke(payload: dict) -> dict:
    # `payload` is the JSON body someone POSTed to /invocations, already parsed
    # into a Python dict. We agreed the caller sends {"diff": "<the code diff>"}.
    diff = payload.get("diff", "")

    # Run the exact same multi-agent board from Phase 2. Returns a Review object.
    review = run_board(diff)

    # The HTTP response must be plain JSON, not a Python object. Pydantic's
    # .model_dump() turns our Review into a dict, which the app serializes to JSON.
    return review.model_dump()


if __name__ == "__main__":
    # Start the server: binds 0.0.0.0:8080 and serves /ping + /invocations.
    app.run()