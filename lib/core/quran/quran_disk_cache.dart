import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Plain-file store for downloaded Quran text.
///
/// Each entry is a JSON list of strings (one per ayah), either for one surah
/// or for the whole Quran. Files are written to a temp path and renamed, so
/// an interrupted download never leaves a half-written entry behind.
class QuranDiskCache {
  Directory? _dir;

  Future<Directory> _root() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/quran');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return _dir = dir;
  }

  Future<File> _file(String key) async => File('${(await _root()).path}/$key.json');

  Future<bool> has(String key) async => (await _file(key)).exists();

  Future<List<String>?> read(String key) async {
    final file = await _file(key);
    if (!await file.exists()) return null;
    try {
      final raw = await file.readAsString();
      // Whole-Quran files are 1–2 MB; decode those off the UI thread.
      final decoded = raw.length > 200000
          ? await Isolate.run(() => jsonDecode(raw) as List<dynamic>)
          : jsonDecode(raw) as List<dynamic>;
      return decoded.cast<String>();
    } catch (e) {
      debugPrint('[QuranDiskCache] corrupt entry $key, discarding: $e');
      await file.delete().catchError((_) => file);
      return null;
    }
  }

  Future<void> write(String key, List<String> values) async {
    final file = await _file(key);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(values), flush: true);
    await tmp.rename(file.path);
  }

  Future<void> delete(String key) async {
    final file = await _file(key);
    if (await file.exists()) await file.delete();
  }

  /// Keys currently on disk that start with [prefix].
  Future<List<String>> keys(String prefix) async {
    final dir = await _root();
    return dir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.json') && n.startsWith(prefix))
        .map((n) => n.substring(0, n.length - 5))
        .toList();
  }

  /// Total bytes used by downloaded Quran text.
  Future<int> sizeInBytes() async {
    final dir = await _root();
    var total = 0;
    for (final f in dir.listSync().whereType<File>()) {
      total += await f.length();
    }
    return total;
  }

  Future<void> clear() async {
    final dir = await _root();
    if (await dir.exists()) await dir.delete(recursive: true);
    _dir = null;
  }
}
