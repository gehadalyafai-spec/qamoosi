import 'package:flutter/material.dart';

import '../practice/practice_stats.dart';

/// Read-only progress, derived from existing stable flashcard identifiers.
/// Unknown saved IDs are ignored; no new persistence keys are required.
class LearningLevelProgress {
  const LearningLevelProgress({
    required this.label,
    required this.learned,
    required this.total,
    required this.completedLessons,
    required this.lessonCount,
  });

  final String label;
  final int learned;
  final int total;
  final int completedLessons;
  final int lessonCount;

  int get remaining => (total - learned).clamp(0, total).toInt();

  double get fraction => total == 0
      ? 0
      : (learned / total).clamp(0.0, 1.0).toDouble();

  static LearningLevelProgress fromCardIds({
    required String label,
    required Iterable<Iterable<String>> lessonCardIds,
    required Set<String> knownIds,
  }) {
    final lessons = [
      for (final ids in lessonCardIds) ids.toSet(),
    ];
    var total = 0;
    var learned = 0;
    var completedLessons = 0;
    for (final ids in lessons) {
      total += ids.length;
      final mastered = ids.where(knownIds.contains).length;
      learned += mastered;
      if (ids.isNotEmpty && mastered == ids.length) {
        completedLessons++;
      }
    }
    return LearningLevelProgress(
      label: label,
      learned: learned,
      total: total,
      completedLessons: completedLessons,
      lessonCount: lessons.length,
    );
  }
}

/// Additional achievement details with a quick path to the next useful task.
/// No widget here changes the scores or the saved flashcard progress.
class LearningOverviewPanel extends StatelessWidget {
  const LearningOverviewPanel({
    super.key,
    required this.levels,
    required this.practiceStats,
    required this.pendingMistakes,
    required this.nextLessonTitle,
    required this.onContinueLesson,
    required this.onPractice,
    required this.onReviewMistakes,
  });

  final List<LearningLevelProgress> levels;
  final PracticeStats practiceStats;
  final int pendingMistakes;
  final String? nextLessonTitle;
  final VoidCallback? onContinueLesson;
  final VoidCallback onPractice;
  final VoidCallback? onReviewMistakes;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF101D32);
    const muted = Color(0xFF667085);
    const violet = Color(0xFF6857CE);
    const green = Color(0xFF21865B);
    const orange = Color(0xFFFF653B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      key: const Key('achievements_learning_overview'),
      children: [
        const Text('تقدّمك حسب المستوى',
          style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w900, color: navy)),
        const SizedBox(height: 6),
        const Text('المتقنة والمتبقية من كلمات كل مستوى',
          style: TextStyle(fontSize: 13, color: muted)),
        const SizedBox(height: 13),
        for (var i = 0; i < levels.length; i++) ...[
          Container(
            key: Key('achievements_level_$i'),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(21),
              border: Border.all(color: const Color(0xFFE9E7F2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: i.isEven
                          ? const Color(0xFFF1EEFF)
                          : const Color(0xFFFFF1E8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      i.isEven
                          ? Icons.school_outlined
                          : Icons.auto_awesome_outlined,
                      size: 23,
                      color: i.isEven ? violet : orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(levels[i].label, style: const TextStyle(
                      color: navy, fontSize: 17,
                      fontWeight: FontWeight.w800)),
                  ),
                  Text('${(levels[i].fraction * 100).round()}%',
                    key: Key('achievements_level_percent_$i'),
                    style: const TextStyle(
                      color: violet, fontSize: 18,
                      fontWeight: FontWeight.w900)),
                ]),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    key: Key('achievements_level_progress_$i'),
                    value: levels[i].fraction,
                    minHeight: 9,
                    color: i.isEven ? violet : orange,
                    backgroundColor: const Color(0xFFF0EEF5),
                  ),
                ),
                const SizedBox(height: 11),
                Wrap(
                  spacing: 14,
                  runSpacing: 7,
                  children: [
                    Text('أتقنت ${levels[i].learned} من ${levels[i].total}',
                      style: const TextStyle(color: navy, fontSize: 13,
                        fontWeight: FontWeight.w700)),
                    Text('المتبقي: ${levels[i].remaining}',
                      style: const TextStyle(color: muted, fontSize: 13)),
                    Text('الدروس المكتملة: ${levels[i].completedLessons} / ${levels[i].lessonCount}',
                      style: const TextStyle(color: muted, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
        ],
        const SizedBox(height: 9),
        Container(
          key: const Key('achievements_next_step'),
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            color: const Color(0xFFECF7F0),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(children: [
            const Icon(Icons.route_rounded, color: green, size: 29),
            const SizedBox(width: 13),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nextLessonTitle == null
                    ? 'أكملت المسار التعليمي!'
                    : 'خطوتك التالية: $nextLessonTitle',
                  key: const Key('achievements_next_lesson'),
                  style: const TextStyle(
                    color: navy, fontSize: 15,
                    fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text(nextLessonTitle == null
                    ? 'واصل مراجعة الكلمات للحفاظ على تقدمك.'
                    : 'تابع الكلمات التي لم تتقنها بعد.',
                  style: const TextStyle(
                    fontSize: 12, color: muted)),
                if (onContinueLesson != null) ...[
                  const SizedBox(height: 11),
                  TextButton.icon(
                    key: const Key('achievements_continue_lesson'),
                    onPressed: onContinueLesson,
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text('أكمل الدرس المقترح'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: green,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            )),
          ]),
        ),
        const SizedBox(height: 26),
        const Text('التدريب والفهم العملي',
          style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w900, color: navy)),
        const SizedBox(height: 12),
        Container(
          key: const Key('achievements_practice_stats'),
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE9E7F2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.psychology_rounded, color: violet, size: 27),
                SizedBox(width: 10),
                Expanded(child: Text('نتائج التدريب العملي',
                  style: TextStyle(
                    color: navy, fontSize: 16,
                    fontWeight: FontWeight.w800))),
              ]),
              const SizedBox(height: 12),
              if (practiceStats.attempts == 0) ...[
                const Text('لم تكمل تدريبًا عمليًا بعد.',
                  style: TextStyle(color: muted, fontSize: 13)),
              ] else ...[
                Text('آخر نتيجة: ${practiceStats.lastScore} من 6',
                  style: const TextStyle(
                    color: navy, fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text('أفضل نتيجة: ${practiceStats.bestScore} من 6',
                  style: const TextStyle(color: muted, fontSize: 13)),
                const SizedBox(height: 5),
                Text('التدريبات المكتملة: ${practiceStats.attempts}',
                  style: const TextStyle(color: muted, fontSize: 13)),
              ],
              const SizedBox(height: 13),
              OutlinedButton.icon(
                key: const Key('achievements_open_practice'),
                onPressed: onPractice,
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: Text(practiceStats.attempts == 0
                    ? 'ابدأ تدريبًا عمليًا'
                    : 'تدريب جديد'),
              ),
              const Divider(height: 29),
              Row(children: [
                const Icon(Icons.rule_rounded, color: orange, size: 23),
                const SizedBox(width: 10),
                Expanded(child: Text('أخطاء تحتاج مراجعة: $pendingMistakes',
                  key: const Key('achievements_mistakes_count'),
                  style: const TextStyle(
                    color: navy, fontSize: 14,
                    fontWeight: FontWeight.w800))),
              ]),
              const SizedBox(height: 6),
              Text(pendingMistakes == 0
                  ? 'لا توجد مواقف خاطئة معلّقة حاليًا.'
                  : 'ابدأ بالأخطاء الأكثر تكرارًا لتثبيت المفاهيم.',
                style: const TextStyle(color: muted, fontSize: 12)),
              if (pendingMistakes > 0 && onReviewMistakes != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('achievements_review_mistakes'),
                  onPressed: onReviewMistakes,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('راجع أخطاء التدريب'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
