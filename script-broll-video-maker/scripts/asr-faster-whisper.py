#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description="Transcribe audio with faster-whisper.")
    parser.add_argument("--audio", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--language", default="")
    parser.add_argument("--model", default="small")
    args = parser.parse_args()

    try:
        from faster_whisper import WhisperModel
    except Exception as exc:
        raise SystemExit(
            "faster-whisper is not installed. Install faster-whisper or use AsrProvider=command. "
            f"Import error: {exc}"
        )

    model = WhisperModel(args.model, device="cpu", compute_type="int8")
    kwargs = {
        "vad_filter": True,
        "word_timestamps": False,
    }
    if args.language:
        kwargs["language"] = args.language

    segments, info = model.transcribe(args.audio, **kwargs)
    items = []
    texts = []
    for segment in segments:
        text = (segment.text or "").strip()
        if not text:
            continue
        texts.append(text)
        items.append(
            {
                "start_seconds": round(float(segment.start), 3),
                "end_seconds": round(float(segment.end), 3),
                "text": text,
            }
        )

    output = {
        "provider": "faster-whisper",
        "model": args.model,
        "language": getattr(info, "language", args.language or ""),
        "language_probability": getattr(info, "language_probability", None),
        "audio_path": str(Path(args.audio).resolve()),
        "text": " ".join(texts).strip(),
        "segments": items,
    }

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(output, ensure_ascii=False, indent=2), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
