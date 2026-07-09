#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def cjk_score(value: str) -> int:
    return sum(1 for ch in value if "\u4e00" <= ch <= "\u9fff")


def repair_text(value: str) -> str:
    if not isinstance(value, str) or not value:
        return value or ""
    best = value
    best_score = cjk_score(value)
    for encoding in ("cp1252", "latin1"):
        try:
            candidate = value.encode(encoding).decode("utf-8")
        except Exception:
            continue
        score = cjk_score(candidate)
        if score > best_score:
            best = candidate
            best_score = score
    return best


def offset_seconds(item: dict, key: str) -> float:
    offsets = item.get("offsets") or {}
    value = offsets.get(key, 0)
    try:
        return round(float(value) / 1000.0, 3)
    except Exception:
        return 0.0


def main() -> int:
    parser = argparse.ArgumentParser(description="Convert whisper.cpp JSON to Script B-roll ASR JSON.")
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--audio", required=True)
    parser.add_argument("--language", default="")
    args = parser.parse_args()

    data = json.loads(Path(args.input).read_text(encoding="utf-8"))
    language = args.language or (data.get("result") or {}).get("language", "")
    segments = []
    texts = []
    for item in data.get("transcription") or []:
        text = repair_text(item.get("text", "")).strip()
        if not text:
            continue
        start = offset_seconds(item, "from")
        end = offset_seconds(item, "to")
        if end <= start:
            continue
        texts.append(text)
        segments.append(
            {
                "start_seconds": start,
                "end_seconds": end,
                "text": text,
            }
        )

    output = {
        "provider": "whisper.cpp",
        "model": (data.get("params") or {}).get("model", ""),
        "language": language,
        "audio_path": str(Path(args.audio).resolve()),
        "text": "".join(texts).strip(),
        "segments": segments,
    }
    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(output, ensure_ascii=False, indent=2), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
