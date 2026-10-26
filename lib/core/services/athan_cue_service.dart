import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// A short phrase of the adhan, played as a cue at a meaningful moment:
/// "come to prayer" as the user begins onboarding, "come to success" as they
/// finish it.
enum AthanCue {
  salah(
    'audio/hayya_alas_salah.m4a',
    'حَيَّ عَلَى الصَّلَاةِ',
    'Hayya ʿala-ṣ-ṣalāh',
    'Come to prayer',
  ),
  falah(
    'audio/hayya_alal_falah.m4a',
    'حَيَّ عَلَى الْفَلَاحِ',
    'Hayya ʿala-l-falāḥ',
    'Come to success',
  );

  /// Path under assets/, as audioplayers' [AssetSource] expects.
  final String asset;
  final String arabic;
  final String transliteration;
  final String meaning;

  const AthanCue(this.asset, this.arabic, this.transliteration, this.meaning);
}

/// Plays [AthanCue]s. Quiet by design: it follows the ringer's silent mode,
/// mixes with whatever else is playing instead of pausing it, and a missing
/// clip is skipped rather than surfaced, since the cue only adds to a tap
/// that already works without it.
class AthanCueService {
  AthanCueService._();
  static final AthanCueService instance = AthanCueService._();

  AudioPlayer? _player;

  /// Set by the speaker button on the onboarding header.
  final ValueNotifier<bool> muted = ValueNotifier(false);

  /// The cue now sounding, for a caption to follow along with.
  final ValueNotifier<AthanCue?> playing = ValueNotifier(null);

  AudioPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;
    final player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    player.setAudioContext(AudioContextConfig(
      respectSilence: true,
      focus: AudioContextConfigFocus.mixWithOthers,
    ).build());
    player.onPlayerComplete.listen((_) => playing.value = null);
    return _player = player;
  }

  /// Starts [cue] and returns once it has begun (or been skipped). Muted, the
  /// caption still shows briefly so the moment isn't lost.
  Future<void> play(AthanCue cue) async {
    playing.value = cue;
    if (muted.value) {
      Future.delayed(const Duration(milliseconds: 2400), () {
        if (playing.value == cue) playing.value = null;
      });
      return;
    }
    try {
      final player = _ensurePlayer();
      await player.stop();
      await player.setVolume(0.85);
      await player.play(AssetSource(cue.asset));
    } catch (e) {
      debugPrint('[AthanCue] ${cue.name} not played: $e');
      playing.value = null;
    }
  }

  Future<void> stop() async {
    playing.value = null;
    await _player?.stop();
  }

  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
    playing.value = null;
  }
}
