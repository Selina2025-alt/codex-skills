# TTS Provider Interface

Every TTS provider must accept exact segment text and create one WAV file for that segment. Providers must not rewrite, summarize, translate, add SSML words, or otherwise alter the spoken content.

## Providers

- `local-sapi`: built-in Windows SAPI provider.
- `command`: external provider command or script. Use this for future API TTS adapters.

## Command Provider Request

The runner writes one request per segment:

```json
{
  "segment_id": "seg_001",
  "text": "Exact source text segment.",
  "text_hash": "<sha256>",
  "voice": "default",
  "output_audio": "C:\\path\\to\\audio\\seg_001.wav",
  "format": "wav"
}
```

For PowerShell providers, the runner calls:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "provider.ps1" `
  -RequestPath "audio/tts_requests/seg_001.json" `
  -OutputPath "audio/seg_001.wav"
```

Other executables are called with:

```text
--request <json> --output <wav>
```

Command templates may use:

```text
{request}
{output}
{segment_id}
```

## Required Output

The provider must create a valid WAV at the requested output path. The orchestrator measures duration with `ffprobe` and writes:

```json
{
  "provider": "command",
  "command": "C:\\path\\to\\provider.ps1",
  "voice": "default",
  "source_hash": "<sha256>",
  "segments": [
    {
      "id": "seg_001",
      "text_hash": "<sha256>",
      "audio_path": "audio/seg_001.wav",
      "duration_seconds": 6.42
    }
  ],
  "narration_path": "audio/narration.wav",
  "total_duration_seconds": 6.42
}
```

Provider swaps must not change segment ids, source text, audio manifest schema, subtitles, timeline, or renderer inputs.
