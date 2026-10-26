import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// The phrases of the iqamah, in order. Onboarding sounds one as the user
/// enters each step, so walking through it recites the whole call, ending
/// with "the prayer has begun" as they finish.
///
/// Until Wird has its own recording, the clips are cut from "Adhan.ogg" by
/// Aishatu98 on Wikimedia Commons (CC0, public domain), an iqamah whose
/// phrases are short and crisp, faded and loudness-normalised:
/// https://commons.wikimedia.org/wiki/File:Adhan.ogg
/// To use another muezzin, replace the files under assets/audio/ keeping
/// their names; nothing else depends on the recording. Keep each clip under
/// about 20s at 22 kHz mono: Android's low-latency player truncates sounds
/// past roughly 1 MB decoded.
enum AthanCue {
  takbir(
    'audio/allahu_akbar.m4a',
    'اللَّهُ أَكْبَرُ',
    'Allāhu akbar',
    'Allah is the greatest',
  ),
  shahada(
    'audio/ashhadu_an_la_ilaha.m4a',
    'أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ',
    'Ashhadu an lā ilāha illā-llāh',
    'There is no god but Allah',
  ),
  risalah(
    'audio/ashhadu_anna_muhammad.m4a',
    'أَشْهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللَّهِ',
    'Ashhadu anna Muḥammadan rasūlu-llāh',
    'Muhammad is the Messenger of Allah',
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
  ),

  /// Qad qāmati-ṣ-ṣalāh twice, then the closing takbir and tahlil in one
  /// clip, so the call finishes as home arrives.
  iqamah(
    'audio/qad_qamat_closing.m4a',
    'قَدْ قَامَتِ الصَّلَاةُ',
    'Qad qāmati-ṣ-ṣalāh',
    'The prayer has begun',
    later: [
      (Duration(milliseconds: 6000), CuePhrase('اللَّهُ أَكْبَرُ', 'Allah is the greatest')),
      (Duration(milliseconds: 9900), CuePhrase('لَا إِلَٰهَ إِلَّا اللَّهُ', 'There is no god but Allah')),
    ],
  );

  /// Path under assets/, as audioplayers' [AssetSource] expects.
  final String asset;
  final String arabic;
  final String transliteration;
  final String meaning;

  /// Further phrases inside the same clip, by how far in they start, so the
  /// caption can follow a clip that says more than one thing.
  final List<(Duration, CuePhrase)> later;

  const AthanCue(this.asset, this.arabic, this.transliteration, this.meaning, {this.later = const []});

  CuePhrase get phrase => CuePhrase(arabic, meaning);
}

/// What a caption shows for one phrase.
class CuePhrase {
  final String arabic;
  final String meaning;

  const CuePhrase(this.arabic, this.meaning);

  @override
  bool operator ==(Object other) => other is CuePhrase && other.arabic == arabic && other.meaning == meaning;

  @override
  int get hashCode => Object.hash(arabic, meaning);
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

  /// The phrase now sounding, for a caption to follow along with.
  final ValueNotifier<CuePhrase?> playing = ValueNotifier(null);

  /// True while a screen (onboarding) draws the caption itself, which hides
  /// the app-wide one so a phrase never shows twice.
  final ValueNotifier<bool> captionedLocally = ValueNotifier(false);

  static const _captionFor = Duration(milliseconds: 4000);
  final List<Timer> _captionTimers = [];

  /// Walks the caption through [cue]'s phrases, then clears it.
  void _caption(AthanCue cue) {
    for (final t in _captionTimers) {
      t.cancel();
    }
    _captionTimers.clear();
    playing.value = cue.phrase;
    for (final (at, phrase) in cue.later) {
      _captionTimers.add(Timer(at, () => playing.value = phrase));
    }
    final last = cue.later.isEmpty ? Duration.zero : cue.later.last.$1;
    _captionTimers.add(Timer(last + _captionFor, () => playing.value = null));
  }

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
    _caption(cue);
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
    }
  }

  Future<void> stop() async {
    for (final t in _captionTimers) {
      t.cancel();
    }
    playing.value = null;
    for (final player in _players.values) {
      await player.stop();
    }
  }
}
