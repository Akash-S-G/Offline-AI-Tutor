# Voice API Contract V1

This document freezes the WebSocket communication protocol between the Flutter thin client and the AI Inference Server. All payloads are strict JSON.

## General Structure

Every message must include a `type` field.

Outgoing requests from the client should ideally include session and identity details:
- `session_id`
- `device_id`
- `student_id`

---

## 1. Client to Server Events

### Audio Stream Event

Fired continuously while the student is speaking.

```json
{
  "type": "audio_chunk",
  "session_id": "sess_12345",
  "device_id": "dev_abcde",
  "student_id": "stu_9876",
  "sequence": 1,
  "payload": {
    "audio": "base64_encoded_pcm_data..."
  }
}
```

### Audio Upload Complete Event

Fired when the student stops speaking, signaling the backend to process the audio stream.

```json
{
  "type": "audio_complete",
  "session_id": "sess_12345",
  "device_id": "dev_abcde",
  "student_id": "stu_9876",
  "language": "kn",
  "payload": {
    "context": {
      "experiment": "Circuit",
      "state": "active",
      "variables": {
        "switch": "closed",
        "battery": "connected"
      }
    }
  }
}
```

---

## 2. Server to Client Events

### Partial Transcript Event

Fired as the ASR model processes the stream to provide instant visual feedback.

```json
{
  "type": "partial_transcript",
  "payload": {
    "text": "current spoken text..."
  }
}
```

### Final Transcript Event

Fired when ASR finishes processing the complete audio chunk.

```json
{
  "type": "final_transcript",
  "payload": {
    "text": "The final processed text."
  }
}
```

### Tutor Response Event

Fired after the LLM generates the response.

```json
{
  "type": "assistant_message",
  "payload": {
    "text": "Response text from the tutor.",
    "language": "kn"
  }
}
```

### Tutor Audio Stream Event

Fired as the TTS engine generates audio chunks. The payload must be base64-encoded WAV/PCM.

```json
{
  "type": "audio_data",
  "payload": {
    "audio": "base64_encoded_audio_data..."
  }
}
```
