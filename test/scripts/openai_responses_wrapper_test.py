from __future__ import annotations

import importlib.util
import pathlib
import sys
import unittest


def load_module():
    root = pathlib.Path(__file__).resolve().parents[2]
    path = root / "scripts" / "openai_responses_wrapper.py"
    spec = importlib.util.spec_from_file_location("openai_responses_wrapper", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load module from {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


wrapper = load_module()


class OpenAIResponsesWrapperTest(unittest.TestCase):
    def test_lookup_model_limits_for_gpt5_codex(self):
        limits = wrapper.lookup_model_limits("gpt-5.2-codex")
        self.assertIsNotNone(limits)
        self.assertEqual(limits.context_window, 400_000)
        self.assertEqual(limits.max_output_tokens, 128_000)

    def test_estimate_remaining_tokens(self):
        self.assertEqual(
            wrapper.estimate_remaining_tokens(400_000, used_tokens=12_345, reserved_tokens=8_000),
            379_655,
        )

    def test_extract_output_text(self):
        response = {
            "output": [
                {
                    "type": "message",
                    "content": [
                        {"type": "output_text", "text": "first "},
                        {"type": "refusal", "refusal": "ignored"},
                    ],
                },
                {"type": "output_text", "text": "second"},
            ],
        }
        self.assertEqual(wrapper.extract_output_text(response), "first second")

    def test_build_input_token_payload_filters_response_only_keys(self):
        payload = {
            "model": "gpt-5",
            "input": "hello",
            "stream": True,
            "store": True,
            "max_output_tokens": 1024,
            "metadata": {"source": "test"},
        }
        filtered = wrapper.build_input_token_payload(payload)
        self.assertEqual(
            filtered,
            {
                "model": "gpt-5",
                "input": "hello",
                "max_output_tokens": 1024,
                "metadata": {"source": "test"},
            },
        )


if __name__ == "__main__":
    unittest.main()
