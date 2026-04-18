#!/usr/bin/env python3
from __future__ import annotations

import argparse
import copy
import json
import os
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any

API_BASE_URL = "https://api.openai.com/v1"
LOG_PREFIX = "[responses-wrapper]"
INPUT_TOKEN_ALLOWED_KEYS = {
    "conversation",
    "input",
    "instructions",
    "max_output_tokens",
    "max_tool_calls",
    "metadata",
    "model",
    "parallel_tool_calls",
    "previous_response_id",
    "reasoning",
    "text",
    "tool_choice",
    "tools",
    "truncation",
}


@dataclass(frozen=True)
class ModelLimits:
    context_window: int
    max_output_tokens: int


KNOWN_MODEL_LIMITS: list[tuple[str, ModelLimits]] = [
    ("gpt-5.2-codex", ModelLimits(context_window=400_000, max_output_tokens=128_000)),
    ("gpt-5-codex", ModelLimits(context_window=400_000, max_output_tokens=128_000)),
    ("gpt-5.2", ModelLimits(context_window=400_000, max_output_tokens=128_000)),
    ("gpt-5.1", ModelLimits(context_window=400_000, max_output_tokens=128_000)),
    ("gpt-5-mini", ModelLimits(context_window=400_000, max_output_tokens=128_000)),
    ("gpt-5-nano", ModelLimits(context_window=400_000, max_output_tokens=128_000)),
    ("gpt-5-chat", ModelLimits(context_window=128_000, max_output_tokens=16_384)),
    ("gpt-5", ModelLimits(context_window=400_000, max_output_tokens=128_000)),
    ("gpt-4.1", ModelLimits(context_window=1_047_576, max_output_tokens=32_768)),
]


def log(message: str) -> None:
    print(f"{LOG_PREFIX} {message}", file=sys.stderr)


def required_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise RuntimeError(f"Missing env: {name}")
    return value


def optional_int_env(name: str) -> int | None:
    raw = os.environ.get(name, "").strip()
    if not raw:
        return None
    try:
        return int(raw)
    except ValueError as exc:
        raise RuntimeError(f"Env {name} must be an integer: {raw}") from exc


def read_text_file(path: str) -> str:
    return Path(path).read_text(encoding="utf-8")


def read_json_file(path: str) -> dict[str, Any]:
    payload = json.loads(read_text_file(path))
    if not isinstance(payload, dict):
        raise RuntimeError(f"JSON payload must be an object: {path}")
    return payload


def set_nested_value(payload: dict[str, Any], key: str, nested_key: str, value: Any) -> None:
    container = payload.get(key)
    if container is None:
        container = {}
        payload[key] = container
    if not isinstance(container, dict):
        raise RuntimeError(f"Payload field '{key}' must be an object to set '{nested_key}'.")
    container[nested_key] = value


def lookup_model_limits(model: str) -> ModelLimits | None:
    normalized = (model or "").strip().lower()
    for prefix, limits in KNOWN_MODEL_LIMITS:
        if normalized == prefix or normalized.startswith(f"{prefix}-"):
            return limits
    return None


def coalesce_int(*values: int | None) -> int | None:
    for value in values:
        if value is not None:
            return value
    return None


def estimate_remaining_tokens(context_window: int | None, used_tokens: int, reserved_tokens: int = 0) -> int | None:
    if context_window is None:
        return None
    return context_window - used_tokens - reserved_tokens


def extract_output_text(response_payload: dict[str, Any]) -> str:
    fragments: list[str] = []
    for item in response_payload.get("output", []):
        if not isinstance(item, dict):
            continue
        if item.get("type") == "message":
            for content in item.get("content", []):
                if isinstance(content, dict) and content.get("type") == "output_text":
                    text = content.get("text")
                    if isinstance(text, str):
                        fragments.append(text)
        elif item.get("type") == "output_text":
            text = item.get("text")
            if isinstance(text, str):
                fragments.append(text)
    return "".join(fragments)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Call the OpenAI Responses API and print token usage plus remaining-context "
            "estimates before and after the request."
        ),
    )
    parser.add_argument("--payload-file", help="JSON file containing a Responses API request body.")
    parser.add_argument("--input", help="Text input for the response request.")
    parser.add_argument("--input-file", help="File path containing text input.")
    parser.add_argument("--instructions", help="Developer/system instructions string.")
    parser.add_argument("--instructions-file", help="File path containing developer/system instructions.")
    parser.add_argument("--model", help="Model name. Defaults to OPENAI_MODEL, CODEX_MODEL, or gpt-5.")
    parser.add_argument("--max-output-tokens", type=int, help="Requested max_output_tokens for the response.")
    parser.add_argument("--context-window", type=int, help="Override the model context window for estimation.")
    parser.add_argument(
        "--model-max-output-tokens",
        type=int,
        help="Override the model max output token limit for clamping and logging.",
    )
    parser.add_argument("--reasoning-effort", help="Set reasoning.effort on the request body.")
    parser.add_argument("--text-verbosity", help="Set text.verbosity on the request body.")
    parser.add_argument("--previous-response-id", help="Set previous_response_id.")
    parser.add_argument("--conversation", help="Set conversation ID.")
    parser.add_argument("--truncation", choices=["auto", "disabled"], help="Set truncation behavior.")
    parser.add_argument(
        "--output-format",
        choices=["json", "text"],
        default="json",
        help="Write raw JSON or extracted assistant text to stdout.",
    )
    parser.add_argument("--response-file", help="Optional file to persist the raw JSON response.")
    return parser.parse_args()


def default_input_text() -> str | None:
    prompt_file = os.environ.get("CODEX_PROMPT_FILE", "").strip()
    if prompt_file and Path(prompt_file).is_file():
        return read_text_file(prompt_file)
    if not sys.stdin.isatty():
        return sys.stdin.read()
    return None


def build_response_payload(args: argparse.Namespace) -> dict[str, Any]:
    payload = read_json_file(args.payload_file) if args.payload_file else {}

    input_value = args.input
    if args.input_file:
        input_value = read_text_file(args.input_file)
    elif input_value is None:
        input_value = default_input_text()

    instructions_value = args.instructions
    if args.instructions_file:
        instructions_value = read_text_file(args.instructions_file)

    model = args.model or os.environ.get("OPENAI_MODEL") or os.environ.get("CODEX_MODEL") or "gpt-5"
    payload["model"] = model

    if input_value is not None and input_value != "":
        payload["input"] = input_value
    if instructions_value is not None and instructions_value != "":
        payload["instructions"] = instructions_value
    if args.max_output_tokens is not None:
        payload["max_output_tokens"] = args.max_output_tokens
    if args.previous_response_id:
        payload["previous_response_id"] = args.previous_response_id
    if args.conversation:
        payload["conversation"] = args.conversation
    if args.truncation:
        payload["truncation"] = args.truncation
    if args.reasoning_effort:
        set_nested_value(payload, "reasoning", "effort", args.reasoning_effort)
    if args.text_verbosity:
        set_nested_value(payload, "text", "verbosity", args.text_verbosity)

    if "input" not in payload:
        raise RuntimeError("Response payload requires 'input'. Use --input, --input-file, stdin, or --payload-file.")
    return payload


def build_input_token_payload(response_payload: dict[str, Any]) -> dict[str, Any]:
    payload = copy.deepcopy(response_payload)
    return {key: value for key, value in payload.items() if key in INPUT_TOKEN_ALLOWED_KEYS}


def openai_request(base_url: str, api_key: str, path: str, payload: dict[str, Any]) -> dict[str, Any]:
    req = urllib.request.Request(
        f"{base_url.rstrip('/')}{path}",
        data=json.dumps(payload).encode("utf-8"),
        method="POST",
    )
    req.add_header("Authorization", f"Bearer {api_key}")
    req.add_header("Content-Type", "application/json")
    req.add_header("Accept", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            body = resp.read().decode("utf-8")
            data = json.loads(body) if body else {}
            if not isinstance(data, dict):
                raise RuntimeError(f"Unexpected JSON response type from {path}.")
            return data
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"API POST {path} failed ({exc.code}): {body}") from exc


def print_preflight_summary(
    *,
    model: str,
    input_tokens: int,
    context_window: int | None,
    reserved_output_tokens: int,
    configured_max_output_tokens: int | None,
    model_output_limit: int | None,
) -> None:
    log(f"model={model}")
    log(f"input_tokens={input_tokens}")
    if context_window is None:
        log("context_window=unknown (set --context-window or OPENAI_CONTEXT_WINDOW to enable remaining-token estimates)")
    else:
        log(f"context_window={context_window}")
        remaining_after_input = estimate_remaining_tokens(context_window, input_tokens)
        log(f"remaining_after_input={remaining_after_input}")

    if configured_max_output_tokens is None:
        log("requested_max_output_tokens=unset")
    else:
        log(f"requested_max_output_tokens={configured_max_output_tokens}")

    if model_output_limit is not None:
        log(f"model_max_output_tokens={model_output_limit}")

    if context_window is not None:
        remaining_after_reserve = estimate_remaining_tokens(context_window, input_tokens, reserved_output_tokens)
        log(f"remaining_after_reserved_output={remaining_after_reserve}")


def print_response_summary(response_payload: dict[str, Any], context_window: int | None) -> None:
    usage = response_payload.get("usage")
    response_id = response_payload.get("id", "")
    if response_id:
        log(f"response_id={response_id}")
    if not isinstance(usage, dict):
        log("usage=unavailable")
        return

    input_tokens = int(usage.get("input_tokens", 0) or 0)
    output_tokens = int(usage.get("output_tokens", 0) or 0)
    total_tokens = int(usage.get("total_tokens", input_tokens + output_tokens) or 0)
    input_details = usage.get("input_tokens_details")
    cached_tokens = 0
    if isinstance(input_details, dict):
        cached_tokens = int(input_details.get("cached_tokens", 0) or 0)
    output_details = usage.get("output_tokens_details")
    reasoning_tokens = 0
    if isinstance(output_details, dict):
        reasoning_tokens = int(output_details.get("reasoning_tokens", 0) or 0)

    log(
        "usage="
        f"input:{input_tokens} output:{output_tokens} reasoning:{reasoning_tokens} "
        f"cached_input:{cached_tokens} total:{total_tokens}"
    )
    if context_window is not None:
        log(f"remaining_after_response={estimate_remaining_tokens(context_window, total_tokens)}")


def write_stdout(output_format: str, response_payload: dict[str, Any]) -> None:
    if output_format == "text":
        sys.stdout.write(extract_output_text(response_payload))
        if sys.stdout.isatty():
            sys.stdout.write("\n")
        return
    json.dump(response_payload, sys.stdout, ensure_ascii=False, indent=2)
    sys.stdout.write("\n")


def main() -> int:
    args = parse_args()
    api_key = required_env("OPENAI_API_KEY")
    base_url = os.environ.get("OPENAI_BASE_URL", API_BASE_URL).strip() or API_BASE_URL

    response_payload = build_response_payload(args)
    model = str(response_payload.get("model", "") or "gpt-5")
    known_limits = lookup_model_limits(model)
    context_window = coalesce_int(
        args.context_window,
        optional_int_env("OPENAI_CONTEXT_WINDOW"),
        known_limits.context_window if known_limits else None,
    )
    model_output_limit = coalesce_int(
        args.model_max_output_tokens,
        optional_int_env("OPENAI_MODEL_MAX_OUTPUT_TOKENS"),
        known_limits.max_output_tokens if known_limits else None,
    )
    configured_max_output_tokens = response_payload.get("max_output_tokens")
    if configured_max_output_tokens is not None and not isinstance(configured_max_output_tokens, int):
        raise RuntimeError("max_output_tokens must be an integer.")
    reserved_output_tokens = configured_max_output_tokens or 0
    if model_output_limit is not None and reserved_output_tokens > model_output_limit:
        log(
            "requested max_output_tokens exceeds model limit; "
            f"clamping reserve estimate from {reserved_output_tokens} to {model_output_limit}"
        )
        reserved_output_tokens = model_output_limit

    input_token_payload = build_input_token_payload(response_payload)
    token_counts = openai_request(base_url, api_key, "/responses/input_tokens", input_token_payload)
    input_tokens = int(token_counts.get("input_tokens", 0) or 0)
    print_preflight_summary(
        model=model,
        input_tokens=input_tokens,
        context_window=context_window,
        reserved_output_tokens=reserved_output_tokens,
        configured_max_output_tokens=configured_max_output_tokens,
        model_output_limit=model_output_limit,
    )

    response = openai_request(base_url, api_key, "/responses", response_payload)
    print_response_summary(response, context_window)

    if args.response_file:
        Path(args.response_file).write_text(
            json.dumps(response, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

    write_stdout(args.output_format, response)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        log(f"ERROR: {exc}")
        raise SystemExit(1)
