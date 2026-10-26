import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// A short phrase of the adhan, played as a cue at a meaningful moment in
/// onboarding: the takbir as the user begins, "come to prayer" as they turn
/// on reminders, "come to success" as they finish.
///
/// The clips are cut from "Beautiful adhan.ogg" by Adam-synagda on Wikimedia
/// Commons (CC0, public domain), faded and loudness-normalised:
/// https://commons.wikimedia.org/wiki/File:Beautiful_adhan.ogg
/// To use another muezzin, replace the files under assets/audio/ keeping
/// their names; nothing else depends on the recording.
enum AthanCue {
  takbir(
    'audio/allahu_akbar.m4a',
    'اللَّهُ أَكْبَرُ',
    'Allāhu akbar',
    'God is the greatest',
  ),
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

  /// One player per cue, each with its clip already loaded, so a cue sounds
  /// the moment it's asked for. Android's MediaPlayer took about a second to
  /// start even with the clip prepared (Galaxy S21 FE), long enough to miss
  /// the moment it belongs to, so these use the low-latency SoundPool. That
  /// reports no completion, so the caption runs on [_captionFor] instead.
  final Map<AthanCue, AudioPlayer> _players = {};
  Future<void>? _warming;
  AthanCue? _sounding;

  /// Set by the speaker button on the onboarding header.
  final ValueNotifier<bool> muted = ValueNotifier(false);

  /// The cue now sounding, for a caption to follow along with.
  final ValueNotifier<AthanCue?> playing = ValueNotifier(null);

  static const _captionFor = Duration(milliseconds: 4500);

  /// Prepares every clip. Safe to call more than once.
  Future<void> warmUp() => _warming ??= _prepareAll();

  Future<void> _prepareAll() async {
    for (final cue in AthanCue.values) {
      try {
        final player = AudioPlayer();
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setAudioContext(AudioContextConfig(
          respectSilence: true,
          focus: AudioContextConfigFocus.mixWithOthers,
        ).build());
        await player.setVolume(0.85);
        await player.setSource(AssetSource(cue.asset));
        _players[cue] = player;
      } catch (e) {
        debugPrint('[AthanCue] ${cue.name} not prepared: $e');
      }
    }
  }

  /// Starts [cue] and returns once it has begun (or been skipped). Muted, the
  /// caption still shows so the moment isn't lost.
  Future<void> play(AthanCue cue) async {
    debugPrint('[AthanCue] ${cue.name}${muted.value ? ' (muted)' : ''}');
    playing.value = cue;
    Future.delayed(_captionFor, () {
      if (playing.value == cue) playing.value = null;
    });
    if (muted.value) return;
    try {
      await warmUp();
      final player = _players[cue];
      if (player == null) throw StateError('clip missing');
      final sounding = _sounding;
      if (sounding != null && sounding != cue) _players[sounding]?.stop();
      _sounding = cue;
      await player.stop();
      await player.resume();
    } catch (e) {
      debugPrint('[AthanCue] ${cue.name} not played: $e');
      if (playing.value == cue) playing.value = null;
    }
  }

  Future<void> stop() async {
    playing.value = null;
    for (final player in _players.values) {
      await player.stop();
    }
  }
}
