/// Six broad curriculum sections. Original lessons are preserved as internal
/// units so historical progress, quiz rotation and review IDs never change.
class VocabularySection {
  const VocabularySection({
    required this.id,
    required this.title,
    required this.description,
    required this.lessonTitles,
  });

  final String id;
  final String title;
  final String description;
  final List<String> lessonTitles;
}

const vocabularySections = <VocabularySection>[
  VocabularySection(
    id: 'digital_basics',
    title: 'أساسيات التقنية والحاسوب',
    description: 'الأجهزة والملفات والهاتف والمستندات',
    lessonTitles: [
      'الملفات والمجلدات',
      'تشغيل البرامج',
      'الحاسوب ومكوناته',
      'الهاتف والتطبيقات اليومية',
      'الملفات والمستندات الرقمية',
    ],
  ),
  VocabularySection(
    id: 'programming',
    title: 'البرمجة وتطوير التطبيقات',
    description: 'البرمجة وFlutter وGit وتطوير الجوال',
    lessonTitles: [
      'أساسيات البرمجة',
      'الأخطاء والتطوير',
      'Git وGitHub',
      'أساسيات Dart وFlutter',
      'هياكل البيانات والكائنات',
      'تطوير تطبيقات الجوال ونشرها',
      'بنية البرامج وصيانتها',
    ],
  ),
  VocabularySection(
    id: 'web_and_design',
    title: 'الويب وتصميم الواجهات',
    description: 'واجهات المستخدم والويب وواجهات API',
    lessonTitles: [
      'عناصر واجهة التطبيق',
      'التصميم وتجربة المستخدم',
      'الويب وقواعد البيانات',
      'تقنيات الويب الحديثة',
      'واجهات API والاتصال',
    ],
  ),
  VocabularySection(
    id: 'security_cloud',
    title: 'الشبكات والأمان والسحابة',
    description: 'الاتصال والحماية والاستضافة والتكاملات',
    lessonTitles: [
      'الحسابات والحماية الأساسية',
      'الإنترنت والاتصال بالشبكة',
      'مفاهيم الأمان الرقمي',
      'السحابة والتشغيل الاحترافي',
      'التكاملات وأحداث الأنظمة',
    ],
  ),
  VocabularySection(
    id: 'commerce_management',
    title: 'التجارة الإلكترونية وإدارة العمل',
    description: 'المشاريع والمنتجات والطلبات والشحن',
    lessonTitles: [
      'إدارة المشاريع والعمل الجماعي',
      'التجارة الإلكترونية وإدارة المنتجات',
      'الطلبات والسداد الإلكتروني',
      'الشحن والطلبات وخدمة العملاء',
    ],
  ),
  VocabularySection(
    id: 'data_ai',
    title: 'البيانات والذكاء الاصطناعي',
    description: 'SQL والتحليلات والنماذج الذكية',
    lessonTitles: [
      'قواعد البيانات وSQL',
      'الذكاء الاصطناعي وتحليل البيانات',
      'تحليل الأعمال ولوحات البيانات',
      'نماذج اللغة والذكاء الاصطناعي',
    ],
  ),
];

/// Derived, read-only summary of a whole section (unaffected by temporary
/// level or search filters). Counts only catalog IDs, never retired cards.
class SectionProgressSummary {
  const SectionProgressSummary({
    required this.total,
    required this.mastered,
    required this.dueReviews,
    required this.practisedThisWeek,
  });

  final int total;
  final int mastered;
  final int dueReviews;
  final int practisedThisWeek;

  double get masteryFraction =>
      total == 0 ? 0 : (mastered / total).clamp(0.0, 1.0).toDouble();
  int get masteryPercent => (masteryFraction * 100).round();

  factory SectionProgressSummary.fromCardIds({
    required Iterable<String> cardIds,
    required Set<String> knownIds,
    required Set<String> dueIds,
    required Set<String> weeklyIds,
  }) {
    final ids = cardIds.where((id) => id.isNotEmpty).toSet();
    return SectionProgressSummary(
      total: ids.length,
      mastered: ids.intersection(knownIds).length,
      dueReviews: ids.intersection(dueIds).length,
      practisedThisWeek: ids.intersection(weeklyIds).length,
    );
  }
}

class VocabularySectionSelection {
  const VocabularySectionSelection({
    required this.section,
    required this.lessonIndices,
  });

  final VocabularySection section;
  final List<int> lessonIndices;
}

/// Filter the existing lesson catalog into broad sections for display only.
///
/// Level filtering operates on the original lesson; title matches in a section
/// reveal its lessons, and word searches reveal only matching internal lessons.
/// No saved or source lesson identifiers are changed.
List<VocabularySectionSelection> selectVocabularySections({
  required List<String> lessonTitles,
  required bool Function(int index) matchesLevel,
  required bool Function(int index, String query) matchesLesson,
  required String query,
}) {
  final byTitle = <String, int>{
    for (var i = 0; i < lessonTitles.length; i++) lessonTitles[i]: i,
  };
  final search = query.trim().toLowerCase();
  final results = <VocabularySectionSelection>[];
  for (final section in vocabularySections) {
    final matchesSectionName = search.isNotEmpty &&
        (section.title.toLowerCase().contains(search) ||
         section.description.toLowerCase().contains(search));
    final indices = <int>[];
    for (final lessonTitle in section.lessonTitles) {
      final index = byTitle[lessonTitle];
      if (index == null || !matchesLevel(index)) continue;
      if (search.isNotEmpty &&
          !matchesSectionName &&
          !matchesLesson(index, query)) {
        continue;
      }
      indices.add(index);
    }
    if (indices.isNotEmpty) {
      results.add(VocabularySectionSelection(
        section: section,
        lessonIndices: indices,
      ));
    }
  }
  return results;
}
