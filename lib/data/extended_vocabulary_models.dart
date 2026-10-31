/// A self-contained offline vocabulary item with full Arabic teaching notes.
///
/// Existing vocabulary IDs in main.dart are never modified. New IDs in the
/// expansion use the stable `extra_*` namespace to avoid collisions.
class ExtendedVocabularyCard {
  const ExtendedVocabularyCard({
    required this.id,
    required this.word,
    required this.pronunciation,
    required this.translation,
    required this.example,
    required this.explanation,
    required this.projectUse,
    required this.practiceQuestion,
  });

  final String id;
  final String word;
  final String pronunciation;
  final String translation;
  final String example;
  final String explanation;
  final String projectUse;
  final String practiceQuestion;
}

class ExtendedVocabularyLesson {
  const ExtendedVocabularyLesson({
    required this.title,
    required this.cards,
    this.intermediate = false,
  });

  final String title;
  final List<ExtendedVocabularyCard> cards;
  final bool intermediate;
}
