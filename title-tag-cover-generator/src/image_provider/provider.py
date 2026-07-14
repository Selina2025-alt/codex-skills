import base64
import json
import os
import struct
import urllib.request
import zlib
from pathlib import Path


def generate_cover_image(prompt_data, config, out_path):
    provider = config.get("image_provider", "mock")
    out = Path(out_path)
    out.parent.mkdir(parents=True, exist_ok=True)
    if provider == "mock":
        _write_mock_png(out)
        return {"provider": "mock", "path": str(out), "note": "Mock placeholder validates the pipeline only."}
    if provider == "external_api":
        return _call_external_api(prompt_data, config, out)
    raise ValueError(f"Unsupported image_provider: {provider}")


def _write_mock_png(path, width=1080, height=1440):
    black = (0, 0, 0)
    white = (245, 245, 245)
    green = (45, 255, 0)
    rows = []
    for y in range(height):
        row = bytearray([0])
        for x in range(width):
            color = black
            if 110 < y < 120 and 80 < x < 900:
                color = green
            if 280 < y < 400 and 80 < x < 640:
                color = green
            if 445 < y < 565 and 80 < x < 960:
                color = green
            if 650 < y < 1240 and (x in range(50, 55) or x in range(1025, 1030)):
                color = white
            if 650 <= y <= 655 and 50 < x < 1030:
                color = white
            if 1235 <= y <= 1240 and 50 < x < 1030:
                color = white
            if 690 < y < 1200 and 80 < x < 1000 and ((x + y) % 37 == 0 or (x - y) % 53 == 0):
                color = white
            row.extend(color)
        rows.append(bytes(row))
    raw = b"".join(rows)
    png = b"\x89PNG\r\n\x1a\n"
    png += _chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
    png += _chunk(b"IDAT", zlib.compress(raw, 9))
    png += _chunk(b"IEND", b"")
    path.write_bytes(png)


def _chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)


def _call_external_api(prompt_data, config, out):
    api_base_url = config.get("api_base_url")
    if not api_base_url:
        raise ValueError("external_api mode requires api_base_url.")
    api_key_env = config.get("api_key_env", "IMAGE_API_KEY")
    api_key = os.environ.get(api_key_env)
    if not api_key:
        raise ValueError(f"Missing API key environment variable: {api_key_env}")

    payload = {
        "model": config.get("model", ""),
        "size": config.get("size", "3:4"),
        "output_format": config.get("output_format", "png"),
        "prompt": prompt_data,
    }
    req = urllib.request.Request(
        api_base_url,
        data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
        },
        method="POST",
    )
    timeout = int(config.get("timeout_seconds", 120))
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        data = json.loads(resp.read().decode("utf-8"))

    if "image_base64" in data:
        out.write_bytes(base64.b64decode(data["image_base64"]))
    elif "b64_json" in data:
        out.write_bytes(base64.b64decode(data["b64_json"]))
    else:
        raise ValueError("External API response must include image_base64 or b64_json.")
    return {"provider": "external_api", "path": str(out)}
