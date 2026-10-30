"""
One shared model configuration for every agent on the board.

All five agents (the four critics + the supervisor) use the same Nova Lite model
in eu-west-1. Defining it in one factory function means there's a single place to
change the model/temperature. We return a fresh instance each time so every agent
gets its own.
"""

from strands.models import BedrockModel


def make_model() -> BedrockModel:
    return BedrockModel(
        model_id="eu.amazon.nova-lite-v1:0",
        temperature=0.2,
    )