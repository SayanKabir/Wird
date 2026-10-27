import 'dart:io';

import 'package:hive/hive.dart';
import 'package:wird2/core/services/storage_service.dart';
import 'package:wird2/models/quran_bookmark.dart';
import 'package:wird2/models/quran_progress.dart';
import 'package:wird2/models/sunnah.dart';
import 'package:wird2/models/azkar.dart';
import 'package:wird2/models/surah.dart';
import 'package:wird2/models/tasbih.dart';
import 'package:wird2/models/verse.dart';

/// Points Hive at a fresh temporary folder and opens the app's storage there,
/// registering the same adapters main() does. Returns the folder so the
/// caller can delete it.
///
/// Call it from setUp (not inside testWidgets): Hive's file I/O is real
/// async work that the fake test clock would never finish.
Future<Directory> openTestStorage() async {
  final dir = await Directory.systemTemp.createTemp('wird_test_');
  await StorageService().init(path: dir.path);
  void register<T>(int id, TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(id)) Hive.registerAdapter(adapter);
  }

  register(SunnahDifficultyAdapter().typeId, SunnahDifficultyAdapter());
  register(SunnahFrequencyAdapter().typeId, SunnahFrequencyAdapter());
  register(SunnahAdapter().typeId, SunnahAdapter());
  register(AzkarCategoryAdapter().typeId, AzkarCategoryAdapter());
  register(AzkarAdapter().typeId, AzkarAdapter());
  register(TasbihAdapter().typeId, TasbihAdapter());
  register(SurahAdapter().typeId, SurahAdapter());
  register(VerseAdapter().typeId, VerseAdapter());
  register(QuranBookmarkAdapter().typeId, QuranBookmarkAdapter());
  register(QuranProgressAdapter().typeId, QuranProgressAdapter());
  return dir;
}

Future<void> closeTestStorage(Directory dir) async {
  await Hive.close();
  if (dir.existsSync()) await dir.delete(recursive: true);
}
