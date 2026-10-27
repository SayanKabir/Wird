import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'sound_service.dart';
import 'storage_service.dart';
import 'weather_service.dart';

/// Rain and thunder under the home screen's sky, rendered by
/// tool/gen_weather_sounds.py.
///
/// Heard only on the home tab with the app open: it fades out over a couple
/// of seconds when the user moves to another tab or screen, and back in on
/// return. It follows the Rain and thunder setting and the media volume (see
/// appSoundContext), and mixes with other audio instead of pausing it.
class WeatherSoundService {
  static WeatherSoundService? _instance;
  factory WeatherSoundService({StorageService? storageService}) {
    _instance ??= WeatherSoundService._internal(storageService ?? StorageService());
    return _instance!;
  }
  WeatherSoundService._internal(this._storageService);

  final StorageService _storageService;

  AudioPlayer? _rain;
  final List<AudioPlayer> _thunder = [];
  int _lastThunder = -1;

  /// From far-off grumbles to close cracks; see tool/gen_weather_sounds.py.
  static const _thunderClips = [
    'thunder_far',
    'thunder_far_creep',
    'thunder_roll',
    'thunder_roll_long',
    'thunder_grumble',
    'thunder_double',
    'thunder_near',
    'thunder_near_sharp',
  ];
  Future<void>? _loading;
  final math.Random _random = math.Random();

  WeatherCondition _condition = WeatherCondition.clear;
  bool _audible = false;

  /// Rain's current volume, eased toward [_target] by [_fader].
  double _volume = 0;
  Timer? _fader;
  bool _playing = false;

  /// Loudest the rain gets; a backdrop you notice rather than hear, under
  /// every other sound.
  static const double _rainVolume = 0.16;

  /// Seconds for a full fade in or out.
  static const double _fadeSeconds = 2.0;
  static const Duration _fadeStep = Duration(milliseconds: 50);

  bool get _enabled {
    try {
      return _storageService.getSettings().weatherSoundsEnabled;
    } catch (_) {
      return false;
    }
  }

  /// How loud the rain is in this weather, 0..1.
  double get _rainLevel => switch (_condition) {
        WeatherCondition.rain || WeatherCondition.thunderstorm => 1.0,
        WeatherCondition.drizzle => 0.45,
        _ => 0.0,
      };

  double get _target => _enabled && _audible ? _rainLevel * _rainVolume : 0;

  /// The weather the sky is showing.
  void setWeather(WeatherCondition condition) {
    if (condition == _condition) return;
    _condition = condition;
    _fade();
  }

  /// Whether the home screen's sky is what the user is looking at.
  void setAudible(bool audible) {
    if (audible == _audible) return;
    _audible = audible;
    _fade();
  }

  /// Call after the Rain and thunder setting changes.
  void refresh() => _fade();

  /// A lightning flash just lit the sky: thunder follows after a moment,
  /// as it does from a strike a few kilometres away.
  void thunder() {
    if (!_enabled || !_audible || _condition != WeatherCondition.thunderstorm) return;
    final delay = Duration(milliseconds: 400 + _random.nextInt(2200));
    Timer(delay, () async {
      if (!_enabled || !_audible) return;
      try {
        await _load();
        if (_thunder.isEmpty) return;
        // Never the same thunder twice in a row.
        var pick = _random.nextInt(_thunder.length);
        if (_thunder.length > 1 && pick == _lastThunder) {
          pick = (pick + 1 + _random.nextInt(_thunder.length - 1)) % _thunder.length;
        }
        _lastThunder = pick;
        final player = _thunder[pick];
        // Well above the rain, as real thunder is, and a little different
        // every time. Its low rumble is where ears and phone speakers are
        // least sensitive, so it needs far more level than the rain to be
        // heard over it.
        await player.setVolume(0.8 + _random.nextDouble() * 0.2);
        await player.stop();
        await player.resume();
      } catch (e) {
        debugPrint('[WeatherSound] thunder not played: $e');
      }
    });
  }

  Future<void> _load() => _loading ??= _prepare();

  Future<void> _prepare() async {
    final context = appSoundContext;
    try {
      final rain = AudioPlayer();
      // The low-latency player loops without a gap.
      await rain.setPlayerMode(PlayerMode.lowLatency);
      await rain.setReleaseMode(ReleaseMode.loop);
      await rain.setAudioContext(context);
      await rain.setVolume(0);
      await rain.setSource(AssetSource('audio/weather/rain_loop.wav'));
      _rain = rain;
    } catch (e) {
      debugPrint('[WeatherSound] rain not prepared: $e');
    }
    for (final name in _thunderClips) {
      try {
        final player = AudioPlayer();
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setAudioContext(context);
        await player.setSource(AssetSource('audio/weather/$name.wav'));
        _thunder.add(player);
      } catch (e) {
        debugPrint('[WeatherSound] $name not prepared: $e');
      }
    }
  }

  /// Eases the rain toward its target, starting the loop when it needs to be
  /// heard and pausing it once silent.
  void _fade() {
    if (_fader != null) return;
    if (_target == 0 && !_playing) return;
    _fader = Timer.periodic(_fadeStep, (_) => _stepFade());
    _stepFade();
  }

  /// A step still waiting on the player; the next tick skips rather than
  /// starting the loop twice.
  bool _stepping = false;

  Future<void> _stepFade() async {
    if (_stepping) return;
    _stepping = true;
    try {
      await _applyStep();
    } finally {
      _stepping = false;
    }
  }

  Future<void> _applyStep() async {
    final target = _target;
    final step = _rainVolume * _fadeStep.inMilliseconds / 1000 / _fadeSeconds;
    _volume = target > _volume ? math.min(target, _volume + step) : math.max(target, _volume - step);

    try {
      if (!_playing && _volume > 0) {
        await _load();
        final rain = _rain;
        if (rain == null) return _stopFader();
        _playing = true;
        await rain.resume();
      }
      await _rain?.setVolume(_volume);
      if (_volume == 0 && _playing) {
        _playing = false;
        await _rain?.pause();
      }
    } catch (e) {
      debugPrint('[WeatherSound] rain fade: $e');
    }
    if (_volume == target) _stopFader();
  }

  void _stopFader() {
    _fader?.cancel();
    _fader = null;
  }
}
