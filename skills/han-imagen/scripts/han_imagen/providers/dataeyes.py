"""DataEyesAI provider — OpenAI-compatible GPT-Image-2 API.

Base URL: https://cloud.dataeyes.ai/v1
Authentication: DATAAI_API_KEY env var
Default model: gpt-image-2

Thin wrapper over the OpenAI provider — sets OPENAI_API_KEY / OPENAI_BASE_URL
from DATAAI_* env vars and delegates entirely.
"""

from __future__ import annotations

import os
from typing import Any

from ..types import CliArgs

# Re-export for uniform interface (cli.py calls generate_image directly)
from .openai import generate_image as _openai_generate_image


def generate_image(prompt: str, model: str, args: CliArgs) -> bytes:
    """Generate image via DataEyesAI GPT-Image-2 API.

    Injects DATAAI_API_KEY/DATAAI_BASE_URL into OPENAI_* equivalents,
    delegates to the OpenAI provider, then restores original env.
    """
    # Save original env
    saved_key = os.environ.get("OPENAI_API_KEY")
    saved_base = os.environ.get("OPENAI_BASE_URL")

    try:
        api_key = os.environ.get("DATAAI_API_KEY")
        if not api_key:
            raise RuntimeError("DATAAI_API_KEY is required for DataEyesAI provider")
        os.environ["OPENAI_API_KEY"] = api_key
        os.environ.setdefault(
            "OPENAI_BASE_URL",
            os.environ.get("DATAAI_BASE_URL", "https://cloud.dataeyes.ai/v1"),
        )

        return _openai_generate_image(prompt, model, args)
    finally:
        # Restore original env
        if saved_key is not None:
            os.environ["OPENAI_API_KEY"] = saved_key
        else:
            os.environ.pop("OPENAI_API_KEY", None)
        if saved_base is not None:
            os.environ["OPENAI_BASE_URL"] = saved_base
        else:
            os.environ.pop("OPENAI_BASE_URL", None)
