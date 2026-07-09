# Timeline Schema

`timeline/timeline.json` is the renderer contract.

```json
{
  "format": {
    "width": 1920,
    "height": 1080,
    "fps": 30
  },
  "segments": [
    {
      "segment_id": "seg_001",
      "start_seconds": 0.0,
      "end_seconds": 6.42,
      "duration_seconds": 6.42,
      "audio": "audio/seg_001.wav",
      "visual": "assets/selected/seg_001.mp4",
      "subtitle_text": "Exact source text segment."
    }
  ],
  "output": "render/final.mp4"
}
```

All paths are stored relative to the project root.
