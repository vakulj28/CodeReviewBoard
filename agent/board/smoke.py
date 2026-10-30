"""
Phase 1 - the smallest possible agent.

Goal: prove our Python code can reach Amazon Bedrock (the Nova Lite model)
through the Strands Agents SDK, BEFORE we build the full review board.

Think of this as calling one new hire into the room and asking a single
question to check they show up and can hear you.

An "agent" here is just two things stuck together:
  1. a model (Nova Lite), and
  2. a short job description (the system prompt).

Run it (from the agent/ folder):
    AWS_PROFILE=chatbot AWS_REGION=eu-west-1 uv run python -m board.smoke
"""

from strands import Agent
from strands.models import BedrockModel

# 1) Pick the model. We reuse the exact Nova Lite inference profile the Project 1
#    chatbot already uses in eu-west-1, so we know it's enabled on the account.
#    temperature=0.2 => focused, repeatable answers (not creative/random).
model = BedrockModel(
    model_id="eu.amazon.nova-lite-v1:0",
    temperature=0.2,
)

# 2) Wrap the model in an Agent and give it a one-line job description.
#    callback_handler=None just means "don't stream half-sentences to the
#    screen as you think" - we only want the final answer here.
reviewer = Agent(
    model=model,
    system_prompt="You are a terse, senior code reviewer. Name the single biggest issue, briefly.",
    callback_handler=None,
)


def main() -> None:
    # A deliberately risky line for the reviewer to catch.
    code = "eval(request.args.get('expr'))"
    question = f"What's the biggest risk in this Python line?\n\n    {code}"

    # Calling the agent runs its think -> answer loop and returns a result.
    result = reviewer(question)

    print("\n=== Reviewer says ===")
    print(result)


if __name__ == "__main__":
    main()
