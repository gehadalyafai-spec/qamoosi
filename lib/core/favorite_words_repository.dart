import 'package:shared_preferences/shared_preferences.dart';

/// Stores bookmarked vocabulary on the current device for offline access.
class FavoriteWordsRepository {
  const FavoriteWordsRepository._();

  static const storageKey = 'favorite_word_ids_v1';

  static Set<String> normalize(Iterable<String>? ids) {
    if (ids == null) return <String>{};
    return ids.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet();
  }

  static Set<String> toggle(Set<String> current, String cardId) {
    final id = cardId.trim();
    final result = normalize(current);
    if (id.isEmpty) return result;
    if (!result.add(id)) {
      result.remove(id);
    }
    return result;
  }

  static Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return normalize(prefs.getStringList(storageKey));
  }

  static Future<void> save(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final values = normalize(ids).toList()..sort();
    if (!await prefs.setStringList(storageKey, values)) {
      throw StateError('تعذّر حفظ الكلمات المفضلة');
    }
  }
}
