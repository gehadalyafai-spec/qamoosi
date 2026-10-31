import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qamoosi/core/favorite_words_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('normalization removes duplicates, whitespace and empty IDs', () {
    final ids = FavoriteWordsRepository.normalize([
      'variable',
      ' variable ',
      '',
      '  ',
      'function',
    ]);
    expect(ids, {'variable', 'function'});
    expect(FavoriteWordsRepository.normalize(null), isEmpty);
  });

  test('toggle adds, removes and leaves original set unchanged', () {
    final initial = <String>{'function'};
    final added = FavoriteWordsRepository.toggle(initial, ' variable ');
    expect(added, {'function', 'variable'});
    expect(initial, {'function'});
    final removed = FavoriteWordsRepository.toggle(added, 'function');
    expect(removed, {'variable'});
    expect(FavoriteWordsRepository.toggle(removed, '  '), {'variable'});
  });

  test('favorites survive another repository load', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await FavoriteWordsRepository.load(), isEmpty);
    await FavoriteWordsRepository.save({'function', 'variable'});
    final loaded = await FavoriteWordsRepository.load();
    expect(loaded, {'function', 'variable'});
    await FavoriteWordsRepository.save(
      FavoriteWordsRepository.toggle(loaded, 'function'),
    );
    expect(await FavoriteWordsRepository.load(), {'variable'});
  });
}
