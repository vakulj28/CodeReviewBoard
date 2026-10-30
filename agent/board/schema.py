"""
The shape of a review (structured output).

We force the board's final answer into these fixed structures with Pydantic,
instead of free-form text, so downstream code (tests, CI, a UI) can rely on the
fields being there.
"""

from pydantic import BaseModel, Field


class Finding(BaseModel):
    """One issue raised about the code."""

    dimension: str = Field(description="security | performance | style | tests")
    severity: str = Field(description="high | medium | low")
    issue: str = Field(description="What is wrong, in one sentence.")
    suggestion: str = Field(description="How to fix it, in one sentence.")


class Review(BaseModel):
    """The whole board's verdict."""

    summary: str = Field(description="One or two sentence overall summary.")
    findings: list[Finding] = Field(default_factory=list)