
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  // https://mixkit.co/free-sound-effects/ ou https://freesound.org
  static const String _sendSound    = 'sounds/receive.mp3';
  static const String _receiveSound = 'sounds/receive.mp3';

  /// Son joué quand on appuie sur "Notifier" (envoi)
  static Future<void> playSend() async {
    try {
      await _player.stop();
      await _player.play(AssetSource(_sendSound));
      
    } catch (e) {
      // Fallback : vibration si le fichier son est absent
      debugPrint('⚠️ Son envoi introuvable, vibration en fallback: $e');
    }
  }

  /// Son joué quand une notification est reçue (foreground)
  static Future<void> playReceive() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.stop();
      await _player.play(AssetSource(_receiveSound));
       Timer(const Duration(seconds: 90), ()async {
        await _player.stop();
        await _player.dispose();

       });
    } catch (e) {
      // Fallback : vibration si le fichier son est absent
      debugPrint('⚠️ Son réception introuvable, vibration en fallback: $e');
    }
  }

  /// Libère les ressources audio
  static Future<void> dispose() async {
    await _player.stop();
    await _player.dispose();
  }
}