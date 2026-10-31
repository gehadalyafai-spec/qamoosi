import 'extended_vocabulary_models.dart';
import 'expanded_vocabulary_basics.dart';
import 'expanded_vocabulary_specialist.dart';
import 'expanded_vocabulary_everyday_mobile.dart';
import 'expanded_vocabulary_business_ai.dart';

/// Twenty-four extra lessons remain separate from the original six.
/// All historic identifiers and their catalog order are preserved.
const expandedVocabulary = <ExtendedVocabularyLesson>[
  ...expandedVocabularyBasics,
  ...expandedVocabularySpecialist,
  ...expandedVocabularyEverydayAndMobile,
  ...expandedVocabularyBusinessAndAi,
];
