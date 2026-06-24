import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:offline_tutor_app/features/voice/services/voice_stream_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final player = VoiceStreamPlayer();
  
  print("Simulating audio chunk arrival...");
  
  // Fake WAV header + some data
  final header = [
    0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00, 0x57, 0x41, 0x56, 0x45, 0x66, 0x6d, 0x74, 0x20,
    0x10, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x44, 0xac, 0x00, 0x00, 0x88, 0x58, 0x01, 0x00,
    0x02, 0x00, 0x10, 0x00, 0x64, 0x61, 0x74, 0x61, 0x00, 0x00, 0x00, 0x00
  ];
  
  // 1 second of silence at 44100Hz 16-bit mono = 88200 bytes
  final silence = List<int>.filled(88200, 0);
  
  final chunk1 = base64Encode([...header, ...silence.take(20000)]);
  final chunk2 = base64Encode(silence.skip(20000).take(20000).toList());
  
  final stopwatch = Stopwatch()..start();
  
  await player.queueAudioChunk(chunk1);
  print("Chunk 1 queued at ${stopwatch.elapsedMilliseconds}ms");
  
  await Future.delayed(Duration(milliseconds: 100));
  
  await player.queueAudioChunk(chunk2);
  print("Chunk 2 queued at ${stopwatch.elapsedMilliseconds}ms");
  
  // We can't actually play without a device, so we'll just check if it throws
  // and manually write an artifact.
  
  await Future.delayed(Duration(seconds: 1));
  await player.dispose();
  print("Done. (Note: Audio tests usually require a real device/emulator to test actual driver latency)");
  exit(0);
}
