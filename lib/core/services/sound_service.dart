import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'storage_service.dart';

/// The app's UI sounds, rendered by tool/gen_ui_sounds.py from the same
/// recipes as the portfolio's "soft" pack. Tap and tick have variants
/// because the originals vary their pitch on every play.
enum UiSound {
  tap(['tap_0', 'tap_1', 'tap_2']),
  tick(['tick_0', 'tick_1', 'tick_2']),
  pop(['pop']),
  toggleOn(['toggle_on']),
  toggleOff(['toggle_off']),
  complete(['complete']),

  /// Logging a prayer, the app's one real reward.
  prayed(['prayed']),
  prayedJamaah(['prayed_jamaah']),

  /// The festive decorations appearing.
  festive(['festive']),

  /// The location found and the prayer times worked out for it.
  ready(['ready']);

  final List<String> files;
  const UiSound(this.files);
}

/// How the app's own small sounds (UI sounds, rain and thunder) play.
///
/// On the media volume, so the phone's volume buttons turn them up and down
/// like any other sound in the app. At full media volume they're as loud as
/// they're ever meant to be. Marked as UI sounds, and they mix with music or
/// a podcast instead of pausing it. On iOS they follow the silent switch;
/// Android's ringer mode doesn't govern media, so there the app's own
/// switches and the volume buttons silence them.
final AudioContext appSoundContext = AudioContext(
  android: const AudioContextAndroid(
    usageType: AndroidUsageType.media,
    contentType: AndroidContentType.sonification,
    audioFocus: AndroidAudioFocus.none,
  ),
  // Ambient already mixes with other audio; the library rejects adding the
  // mixWithOthers option to it, and checks that on Android too.
  iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
);

/// Plays the micro sounds that go with taps, switches and completions.
///
/// Like [HapticService] it checks `AppSettings.soundsEnabled` on every call,
/// so the Settings toggle silences everything at once. It's meant to be felt
/// more than heard: it plays on the media volume (see [appSoundContext]),
/// mixes with whatever else is playing instead of pausing it, and a sound
/// that fails to load is skipped, since every tap already works without it.
class SoundService {
  static SoundService? _instance;
  factory SoundService({StorageService? storageService}) {
    _instance ??= SoundService._internal(storageService ?? StorageService());
    return _instance!;
  }
  SoundService._internal(this._storageService);

  final StorageService _storageService;

  /// One low-latency player per file, loaded up front so a sound lands on
  /// the tap rather than after it (see AthanCueService for why MediaPlayer
  /// is too slow on Android).
  final Map<String, AudioPlayer> _players = {};
  final Map<UiSound, int> _nextVariant = {};
  Future<void>? _warming;

  /// One sound per gesture. A switch plays its toggle, then the save it
  /// triggers fires a tap haptic; anything within this window of the last
  /// sound is dropped so the two don't stack.
  static const _gap = Duration(milliseconds: 50);
  DateTime _lastPlayed = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _heldUntil = DateTime.fromMillisecondsSinceEpoch(0);

  /// Everything a little under full level: these are meant to be felt more
  /// than heard.
  static const double _volume = 0.7;

  bool get _enabled {
    try {
      return _storageService.getSettings().soundsEnabled;
    } catch (_) {
      // Storage not open yet (very early startup): stay quiet rather than throw.
      return false;
    }
  }

  /// Loads every sound. Safe to call more than once.
  Future<void> warmUp() => _warming ??= _prepareAll();

  Future<void> _prepareAll() async {
    for (final sound in UiSound.values) {
      for (final file in sound.files) {
        try {
          final player = AudioPlayer();
          await player.setPlayerMode(PlayerMode.lowLatency);
          await player.setReleaseMode(ReleaseMode.stop);
          await player.setAudioContext(appSoundContext);
          await player.setVolume(_volume);
          await player.setSource(AssetSource('audio/ui/$file.wav'));
          _players[file] = player;
        } catch (e) {
          debugPrint('[Sound] $file not prepared: $e');
        }
      }
    }
  }

  void tap() => play(UiSound.tap);
  void tick() => play(UiSound.tick);
  void pop() => play(UiSound.pop);
  void complete() => play(UiSound.complete);
  void prayed({bool jamaah = false}) => play(jamaah ? UiSound.prayedJamaah : UiSound.prayed);
  void toggle(bool on) => play(on ? UiSound.toggleOn : UiSound.toggleOff);
  void festive() => play(UiSound.festive);

  /// Rings out over the tap and confirmation that come with it.
  void ready() => play(UiSound.ready, hold: const Duration(milliseconds: 600));

  /// A load that made the user wait has finished: the ready chime, but only
  /// when it took long enough to notice, so cached and instant loads stay
  /// quiet.
  void loaded(Duration took) {
    if (took >= longLoad) ready();
  }

  /// How long a wait has to be before its end is worth a chime.
  /// Surahs fetched from the network mostly take 0.4-1 s; cached ones about
  /// 0.1-0.2 s, which shouldn't chime.
  static const longLoad = Duration(milliseconds: 400);

  /// Plays [sound]; [variant] picks one of its files, otherwise they take
  /// turns. [hold] keeps other sounds quiet for a while after, so a chime
  /// isn't stepped on by the taps of the same moment.
  void play(UiSound sound, {int? variant, Duration hold = Duration.zero}) {
    if (!_enabled) return;
    final now = DateTime.now();
    if (now.difference(_lastPlayed) < _gap || now.isBefore(_heldUntil)) return;
    _lastPlayed = now;
    _heldUntil = now.add(hold);

    final i = variant ?? _nextVariant[sound] ?? 0;
    _nextVariant[sound] = (i + 1) % sound.files.length;
    _start(sound.files[i % sound.files.length]);
  }

  Future<void> _start(String file) async {
    try {
      await warmUp();
      final player = _players[file];
      if (player == null) return;
      await player.stop();
      await player.resume();
    } catch (e) {
      debugPrint('[Sound] $file not played: $e');
    }
  }
}
