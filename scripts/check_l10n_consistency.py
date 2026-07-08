#!/usr/bin/env python3
import json
import pathlib
import re
import sys


ROOT = pathlib.Path(__file__).resolve().parents[1]
ARB_DIR = ROOT / "lib" / "l10n"
TEMPLATE = "app_en.arb"
PLACEHOLDER_RE = re.compile(r"\{([A-Za-z_][A-Za-z0-9_]*)")


def load_arb(path: pathlib.Path) -> dict:
    with path.open(encoding="utf-8") as file:
        return json.load(file)


def message_keys(data: dict) -> set[str]:
    return {key for key in data if not key.startswith("@")}


def metadata_placeholders(data: dict, key: str) -> set[str]:
    metadata = data.get(f"@{key}", {})
    placeholders = metadata.get("placeholders", {})
    return set(placeholders)


def text_placeholders(data: dict, key: str) -> set[str]:
    value = data.get(key, "")
    if not isinstance(value, str):
        return set()
    return set(PLACEHOLDER_RE.findall(value))


def main() -> int:
    arb_paths = sorted(ARB_DIR.glob("app_*.arb"))
    if not arb_paths:
        print("[l10n] No ARB files found.", file=sys.stderr)
        return 1

    by_name = {path.name: load_arb(path) for path in arb_paths}
    if TEMPLATE not in by_name:
        print(f"[l10n] Missing template ARB: {TEMPLATE}", file=sys.stderr)
        return 1

    template = by_name[TEMPLATE]
    template_keys = message_keys(template)
    failed = False

    for name, data in by_name.items():
        keys = message_keys(data)
        missing = sorted(template_keys - keys)
        extra = sorted(keys - template_keys)
        if missing:
            failed = True
            print(f"[l10n] {name}: missing keys: {', '.join(missing)}", file=sys.stderr)
        if extra:
            failed = True
            print(f"[l10n] {name}: extra keys: {', '.join(extra)}", file=sys.stderr)

        for key in sorted(template_keys & keys):
            template_meta = metadata_placeholders(template, key)
            locale_meta = metadata_placeholders(data, key)
            if (template_meta or locale_meta) and locale_meta != template_meta:
                failed = True
                print(
                    f"[l10n] {name}:{key}: metadata placeholders "
                    f"{sorted(locale_meta)} != template {sorted(template_meta)}",
                    file=sys.stderr,
                )

            template_text = text_placeholders(template, key)
            locale_text = text_placeholders(data, key)
            if locale_text != template_text:
                failed = True
                print(
                    f"[l10n] {name}:{key}: text placeholders "
                    f"{sorted(locale_text)} != template {sorted(template_text)}",
                    file=sys.stderr,
                )

    if failed:
        print("[l10n] Localization consistency check failed.", file=sys.stderr)
        return 1

    print("[l10n] Localization consistency check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
