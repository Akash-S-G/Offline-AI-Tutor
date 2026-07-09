from __future__ import annotations

import json
import os
import re
from collections.abc import AsyncIterator
from typing import Any

import httpx

from services.interfaces import TutorEngine


class RagTutorEngine(TutorEngine):
    """HTTP adapter for the existing curriculum tutor pipeline."""

    def __init__(self, base_url: str | None = None, path: str | None = None) -> None:
        self.base_url = (base_url or os.getenv("VOICE_TUTOR_URL") or "http://inference-service:8010").rstrip("/")
        self.path = path or os.getenv("VOICE_TUTOR_PATH") or "/ai/tutor"

    async def answer_with_context(self, question: str, filters: dict[str, Any]) -> dict[str, Any]:
        payload = self._payload(question, filters, stream=False)
        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(f"{self.base_url}{self.path}", json=payload)
        response.raise_for_status()
        result = response.json()
        return {
            "answer": self._clean_text(result.get("answer") or result.get("text") or result.get("chunk") or ""),
            "context": result.get("context") or result.get("sources") or [],
            "raw": result,
        }

    async def stream_answer_with_context(self, question: str, filters: dict[str, Any]) -> AsyncIterator[str]:
        payload = self._payload(question, filters, stream=True)
        async with httpx.AsyncClient(timeout=None) as client:
            async with client.stream("POST", f"{self.base_url}{self.path}", json=payload) as response:
                response.raise_for_status()
                emitted = ""
                async for line in response.aiter_lines():
                    chunk = self._stream_text(line)
                    if chunk:
                        delta = self._stream_delta(emitted, chunk)
                        if delta:
                            emitted = self._merge_text(emitted, chunk)
                            yield delta

    @staticmethod
    def _payload(question: str, filters: dict[str, Any], stream: bool) -> dict[str, Any]:
        return {
            "question": question,
            "grade": filters.get("grade"),
            "subject": filters.get("subject"),
            "chapter": filters.get("chapter") or filters.get("chapter_id"),
            "topic": filters.get("topic"),
            "language": filters.get("language") or "en",
            "experiment": filters.get("experiment"),
            "stream": stream,
        }

    @staticmethod
    def _stream_text(line: str) -> str:
        if not line:
            return ""
        if line.startswith("data:"):
            line = line.removeprefix("data:").strip()
        if line == "[DONE]":
            return ""
        try:
            data = json.loads(line)
        except json.JSONDecodeError:
            return RagTutorEngine._clean_text(line)
        return RagTutorEngine._clean_text(
            str(data.get("token") or data.get("answer") or data.get("text") or data.get("delta") or data.get("content") or data.get("chunk") or "")
        )

    @staticmethod
    def _clean_text(text: str) -> str:
        if not text:
            return ""
        output = text.replace("\r", "")
        output = re.sub(r"<think[^>]*>[\s\S]*?</think>", "", output, flags=re.IGNORECASE)
        output = re.sub(r"<reasoning[^>]*>[\s\S]*?</reasoning>", "", output, flags=re.IGNORECASE)
        output = re.sub(r"<analysis[^>]*>[\s\S]*?</analysis>", "", output, flags=re.IGNORECASE)
        output = re.sub(r"<\|[^>]*\|>", "", output)
        output = re.sub(r"<\|[^\n]*", "", output)
        output = re.sub(r"<[^\s>]*\|>", "", output)
        cleaned_lines: list[str] = []
        started_answer = False
        for raw_line in output.splitlines():
            line = raw_line.strip()
            if not line:
                if started_answer and cleaned_lines and cleaned_lines[-1]:
                    cleaned_lines.append("")
                continue

            lower = line.lower()
            if lower.startswith((
                "student question:",
                "question:",
                "user query:",
                "recent conversation:",
                "session summary:",
                "priority context:",
                "relevant notes:",
                "context:",
                "educational context:",
            )):
                continue

            if lower.startswith(("answer:", "tutor answer:")):
                started_answer = True
                remainder = line.split(":", 1)[1].strip() if ":" in line else ""
                if remainder:
                    cleaned_lines.append(remainder)
                continue

            started_answer = True
            cleaned_lines.append(line)

        return "\n".join(cleaned_lines).strip()

    @staticmethod
    def _merge_text(previous: str, incoming: str) -> str:
        previous = RagTutorEngine._clean_text(previous)
        incoming = RagTutorEngine._clean_text(incoming)
        if not incoming:
            return previous
        if not previous:
            return incoming
        if incoming == previous:
            return previous
        if incoming.startswith(previous):
            return incoming
        if previous.startswith(incoming):
            return previous

        overlap = 0
        max_overlap = min(len(previous), len(incoming))
        for candidate in range(max_overlap, 0, -1):
            if previous[-candidate:] == incoming[:candidate]:
                overlap = candidate
                break
        if overlap:
            return previous + incoming[overlap:]
        return previous + incoming

    @staticmethod
    def _stream_delta(previous: str, incoming: str) -> str:
        merged = RagTutorEngine._merge_text(previous, incoming)
        previous = RagTutorEngine._clean_text(previous)
        if len(merged) <= len(previous):
            return ""
        return merged[len(previous):]
