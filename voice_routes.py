from fastapi import APIRouter, File, Header, HTTPException, Request, UploadFile, WebSocket, WebSocketDisconnect
from fastapi.responses import Response, StreamingResponse
import logging
import json
import base64
import time
import asyncio
from stt.mock_stt import MockSTTEngine
from services.tutor_adapter import InferenceTutorAdapter

from models import STTRequest, STTResponse, TTSRequest, TTSResponse, VoiceQueryRequest, VoiceQueryResponse

logger = logging.getLogger(__name__)
seen_sessions = set()

router = APIRouter()


@router.post("/voice/query", response_model=VoiceQueryResponse, tags=["voice"])
async def voice_query(request: Request, payload: VoiceQueryRequest) -> VoiceQueryResponse:
    gateway = request.app.state.voice_gateway
    return await gateway.query(payload)


@router.post("/voice/tts", response_model=TTSResponse, tags=["voice"])
async def voice_tts(request: Request, payload: TTSRequest) -> TTSResponse | StreamingResponse:
    gateway = request.app.state.voice_gateway
    if payload.stream:
        streamer = request.app.state.voice_streamer
        return StreamingResponse(streamer.tts.stream(payload.text, payload.voice, payload.language, payload.format), media_type=f"audio/{payload.format}")
    return await gateway.tts_only(payload)


@router.post("/voice/stt", response_model=STTResponse, tags=["voice"])
async def voice_stt(
    request: Request,
    language: str | None = None,
    enable_partial_transcripts: bool = False,
    file: UploadFile = File(...),
) -> STTResponse:
    request.app.state.voice_metrics.increment("stt_requests")
    audio = await file.read()
    result = await request.app.state.stt_engine.transcribe(audio, language)
    return STTResponse(
        transcript=str(result.get("transcript") or ""),
        language=str(result.get("language") or language or "unknown"),
        partial_transcripts=list(result.get("partial_transcripts") or []) if enable_partial_transcripts else [],
        confidence=result.get("confidence"),
        metrics=dict(result.get("metrics") or {}),
    )


@router.get("/voice/audio/{asset_id}", tags=["voice", "audio"])
@router.get("/audio/{asset_id}", tags=["audio"])
async def get_audio_asset(request: Request, asset_id: str, range_header: str | None = Header(default=None, alias="Range")) -> Response:
    storage = request.app.state.audio_storage
    audio = await storage.get(asset_id)
    if not audio:
        raise HTTPException(status_code=404, detail={"success": False, "error": {"code": "AUDIO_NOT_FOUND", "message": asset_id}})
    content = audio.content
    headers = {
        "Accept-Ranges": "bytes",
        "Cache-Control": "public, max-age=3600",
        "ETag": audio.checksum or "",
    }
    if range_header:
        start, end = _parse_range(range_header, len(content))
        headers["Content-Range"] = f"bytes {start}-{end}/{len(content)}"
        return Response(content[start : end + 1], status_code=206, media_type=audio.content_type, headers=headers)
    headers["Content-Length"] = str(len(content))
    return Response(content, media_type=audio.content_type, headers=headers)


@router.get("/voice/metrics", tags=["voice", "analytics"])
async def voice_metrics(request: Request) -> dict[str, object]:
    return request.app.state.voice_metrics.snapshot()


@router.websocket("/voice/stream")
@router.websocket("/api/v1/voice/stream")
async def voice_websocket(websocket: WebSocket):
    await websocket.accept()
    await websocket.send_json({"type": "connected", "payload": {}})

    metrics = websocket.app.state.voice_metrics
    metrics.increment("active_connections")
    metrics.increment("voice_sessions")

    audio_buffer = bytearray()
    
    try:
        while True:
            data = await websocket.receive_text()
            try:
                event = json.loads(data)
            except json.JSONDecodeError:
                continue
                
            event_type = event.get("type")
            payload = event.get("payload") or {}
            
            if event_type == "audio_data":
                audio_b64 = payload.get("audio")
                if audio_b64:
                    audio_buffer.extend(base64.b64decode(audio_b64))
            
            elif event_type == "audio_complete":
                language = event.get("language") or "en"
                context = payload.get("context") or {}
                
                if not audio_buffer:
                    continue
                    
                audio_bytes = bytes(audio_buffer)
                audio_buffer.clear()
                
                # STT
                stt_engine = websocket.app.state.stt_engine
                stt_result = await stt_engine.transcribe(audio_bytes, language)
                transcript = stt_result.get("transcript") or ""
                
                await websocket.send_json({
                    "type": "final_transcript",
                    "payload": {"text": transcript}
                })
                
                if not transcript:
                    continue
                
                # Tutor
                tutor_engine = websocket.app.state.tutor_engine
                filters = {"language": language, "experiment": context.get("experiment")}
                tutor_result = await tutor_engine.answer_with_context(transcript, filters)
                answer_text = tutor_result.get("answer") or ""
                
                await websocket.send_json({
                    "type": "assistant_message",
                    "payload": {"text": answer_text}
                })
                
                if not answer_text:
                    continue
                
                # TTS
                tts_engine = websocket.app.state.tts_engine
                async for chunk in tts_engine.stream(answer_text, "default", language, "wav"):
                    await websocket.send_json({
                        "type": "audio_chunk",
                        "payload": {"audio": base64.b64encode(chunk).decode("utf-8")}
                    })
                    
    except WebSocketDisconnect:
        metrics.increment("disconnects")
    except Exception as e:
        import traceback
        traceback.print_exc()
        try:
            await websocket.send_json({"type": "error", "payload": {"message": str(e)}})
        except:
            pass
    finally:
        metrics.increment("active_connections", -1)


def _parse_range(header: str, size: int) -> tuple[int, int]:
    if not header.startswith("bytes="):
        raise HTTPException(status_code=416, detail="Only bytes ranges are supported")
    raw_start, _, raw_end = header.removeprefix("bytes=").partition("-")
    start = int(raw_start or 0)
    end = int(raw_end) if raw_end else size - 1
    if start < 0 or end < start or start >= size:
        raise HTTPException(status_code=416, detail="Invalid range")
    return start, min(end, size - 1)
