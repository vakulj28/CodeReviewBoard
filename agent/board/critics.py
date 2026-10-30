"""
The four specialist critics — the panel.

Each critic is its OWN small Agent with a narrow job. We then wrap each one in
@tool, which turns it into something another agent (our supervisor, next step) is
allowed to CALL — like calling a function.

Key idea: the supervisor decides which tool to call by reading the tool's
docstring, so each docstring is written to say exactly what that critic is for.
Each tool takes the code `diff` as text and returns that critic's findings as text.
"""

from strands import Agent, tool

from board.model import make_model

# --- Each critic's "job description" (system prompt) ---

SECURITY_PROMPT = (
    "You are a security code reviewer. Look ONLY for security problems: injection, "
    "hardcoded secrets, weak authentication/authorization, unsafe deserialization, SSRF. "
    "For each problem give a severity (high/medium/low) and a one-line fix. "
    "If you find none, say 'No security issues found.'"
)

PERFORMANCE_PROMPT = (
    "You are a performance code reviewer. Look ONLY for performance problems: slow or "
    "nested loops, N+1 database queries, needless allocations, blocking I/O on hot paths. "
    "For each problem give a severity (high/medium/low) and a one-line fix. "
    "If you find none, say 'No performance issues found.'"
)

STYLE_PROMPT = (
    "You are a style/readability reviewer. Look ONLY for readability problems: unclear "
    "names, dead code, overly complex functions, missing docstrings or type hints. "
    "For each problem give a severity (high/medium/low) and a one-line fix. "
    "If you find none, say 'No style issues found.'"
)

TESTS_PROMPT = (
    "You are a testing reviewer. Look ONLY for testing gaps: missing tests for new code, "
    "untested edge cases, weak or missing assertions. "
    "For each gap give a severity (high/medium/low) and a one-line fix. "
    "If you find none, say 'No testing gaps found.'"
)


# --- The critics, each exposed as a tool the supervisor can call ---

@tool
def security_critic(diff: str) -> str:
    """Review a code diff for SECURITY issues: injection, secrets, auth, unsafe deserialization, SSRF."""
    agent = Agent(model=make_model(), system_prompt=SECURITY_PROMPT, callback_handler=None)
    return str(agent(diff))


@tool
def performance_critic(diff: str) -> str:
    """Review a code diff for PERFORMANCE issues: slow loops, N+1 queries, wasteful allocations, blocking I/O."""
    agent = Agent(model=make_model(), system_prompt=PERFORMANCE_PROMPT, callback_handler=None)
    return str(agent(diff))


@tool
def style_critic(diff: str) -> str:
    """Review a code diff for STYLE/readability issues: naming, dead code, complexity, missing docs/types."""
    agent = Agent(model=make_model(), system_prompt=STYLE_PROMPT, callback_handler=None)
    return str(agent(diff))


@tool
def tests_critic(diff: str) -> str:
    """Review a code diff for TESTING gaps: missing tests, untested edge cases, weak assertions."""
    agent = Agent(model=make_model(), system_prompt=TESTS_PROMPT, callback_handler=None)
    return str(agent(diff))