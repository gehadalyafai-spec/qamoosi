import 'extended_vocabulary_models.dart';
import 'expanded_vocabulary_basics.dart';
import 'expanded_vocabulary_specialist.dart';

/// Additional content remains separate from the original sixty vocabulary
/// cards. This preserves all existing IDs and stored learner progress.
const expandedVocabulary = <ExtendedVocabularyLesson>[
  ...expandedVocabularyBasics,
  ...expandedVocabularySpecialist,
];
