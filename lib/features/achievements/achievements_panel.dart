import 'package:flutter/material.dart';
import '../../core/quiz_stats.dart';
import '../practice/practice_stats.dart';
import 'learning_overview.dart';
import '../../core/daily_learning_progress.dart';
import '../daily/daily_learning_widgets.dart';

/// A presentation-only summary, derived from the saved flashcard progress.
class LessonAchievement {
  const LessonAchievement({
    required this.title,
    required this.completed,
    required this.total,
  });

  final String title;
  final int completed;
  final int total;

  double get progress => total == 0 ? 0 : (completed / total).clamp(0.0, 1.0).toDouble();
  bool get isCompleted => total > 0 && completed >= total;
}

/// All numbers come from the parent page, so no second storage source is needed.
class AchievementsPanel extends StatelessWidget {
  const AchievementsPanel({
    super.key,
    required this.lessons,
    required this.dueCards,
    required this.scheduledCards,
    required this.quizStats,
    required this.dailyProgress,
    required this.levelProgress,
    required this.practiceStats,
    required this.pendingMistakes,
    required this.nextLessonTitle,
    required this.onContinueLesson,
    required this.onPractice,
    required this.onReviewMistakes,
    required this.onExplore,
  });

  final List<LessonAchievement> lessons;
  final int dueCards;
  final int scheduledCards;
  final QuizStats quizStats;
  final DailyLearningProgress dailyProgress;
  final List<LearningLevelProgress> levelProgress;
  final PracticeStats practiceStats;
  final int pendingMistakes;
  final String? nextLessonTitle;
  final VoidCallback? onContinueLesson;
  final VoidCallback onPractice;
  final VoidCallback? onReviewMistakes;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF101D32);
    const orange = Color(0xFFFF653B);
    const muted = Color(0xFF667085);
    final total = lessons.fold<int>(0, (value, lesson) => value + lesson.total);
    final learned = lessons.fold<int>(0, (value, lesson) => value + lesson.completed);
    final finished = lessons.where((lesson) => lesson.isCompleted).length;
    final fraction = total == 0 ? 0.0 : (learned / total).clamp(0.0, 1.0).toDouble();

    return ListView(
      key: const Key('achievements_scroll'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      children: [
        const Text('إنجازاتي',
          style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900, color: navy)),
        const SizedBox(height: 6),
        const Text('شاهد ما تعلمته وما تبقى لك',
          style: TextStyle(fontSize: 15, color: muted)),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [navy, Color(0xFF32466B)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(27),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFB184)),
                SizedBox(width: 9),
                Text('رحلتك التعليمية', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
              ]),
              const SizedBox(height: 21),
              Text('أتقنت $learned من $total بطاقة', style: const TextStyle(
                color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
              const SizedBox(height: 15),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 10,
                  backgroundColor: Colors.white24,
                  color: const Color(0xFFFFB184),
                ),
              ),
              const SizedBox(height: 10),
              Text('${(fraction * 100).round()}% من إجمالي الكلمات',
                style: const TextStyle(color: Color(0xFFE1E9F6), fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _SummaryTile(
              icon: Icons.check_circle_outline_rounded,
              number: '$finished / ${lessons.length}',
              label: 'دروس مكتملة',
            )),
            const SizedBox(width: 12),
            Expanded(child: _SummaryTile(
              icon: Icons.event_available_rounded,
              number: '$dueCards',
              label: 'مستحقة للمراجعة',
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _SummaryTile(
              icon: Icons.schedule_rounded,
              number: '$scheduledCards',
              label: 'مراجعتها لاحقًا',
            )),
            const SizedBox(width: 12),
            Expanded(child: _SummaryTile(
              icon: Icons.menu_book_rounded,
              number: '${lessons.length}',
              label: 'الدروس المتاحة',
            )),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          key: const Key('achievements_quiz_stats'),
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEE6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.quiz_rounded, color: orange, size: 29),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('نتائج الاختبارات', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: navy)),
                const SizedBox(height: 5),
                Text(quizStats.attempts == 0
                    ? 'لم تُجرِ اختبارًا بعد'
                    : 'آخر نتيجة: ${quizStats.lastScore} من 6  •  الأفضل: ${quizStats.bestScore} من 6',
                  style: const TextStyle(fontSize: 13, color: muted)),
                if (quizStats.attempts > 0) ...[
                  const SizedBox(height: 4),
                  Text('الاختبارات المكتملة: ${quizStats.attempts}',
                    style: const TextStyle(fontSize: 12, color: muted)),
                ],
              ],
            )),
          ]),
        ),
        const SizedBox(height: 23),
        LearningOverviewPanel(
          levels: levelProgress,
          practiceStats: practiceStats,
          pendingMistakes: pendingMistakes,
          nextLessonTitle: nextLessonTitle,
          onContinueLesson: onContinueLesson,
          onPractice: onPractice,
          onReviewMistakes: onReviewMistakes,
        ),
        const SizedBox(height: 23),
        WeeklyLearningPanel(
          progress: dailyProgress,
          now: DateTime.now(),
        ),
        const SizedBox(height: 29),
        const Text('تفاصيل الدروس', style: TextStyle(
          fontWeight: FontWeight.w900, fontSize: 21, color: navy)),
        const SizedBox(height: 6),
        const Text('تقدّمك في كل درس على حدة',
          style: TextStyle(color: muted, fontSize: 14)),
        const SizedBox(height: 13),
        for (final lesson in lessons) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(lesson.title, style: const TextStyle(
                  fontSize: 16, color: navy, fontWeight: FontWeight.w800))),
                const SizedBox(width: 8),
                if (lesson.isCompleted)
                  const Icon(Icons.verified_rounded, color: Color(0xFF21865B), size: 21)
                else
                  Text('${(lesson.progress * 100).round()}%',
                    style: const TextStyle(color: muted, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 9),
              Text('${lesson.completed} من ${lesson.total} كلمات  •  المتبقي: ${(lesson.total - lesson.completed).clamp(0, lesson.total)}',
                style: const TextStyle(color: muted, fontSize: 13)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: lesson.progress,
                  minHeight: 7,
                  backgroundColor: const Color(0xFFF0F1F5),
                  color: lesson.isCompleted ? const Color(0xFF21865B) : orange,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 14),
        FilledButton.icon(
          key: const Key('achievements_explore'),
          onPressed: onExplore,
          icon: const Icon(Icons.menu_book_rounded),
          label: const Text('استعرض الدروس'),
          style: FilledButton.styleFrom(
            backgroundColor: orange,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.number,
    required this.label,
  });

  final IconData icon;
  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 23, color: const Color(0xFF6857CE)),
          const SizedBox(height: 10),
          Text(number, style: const TextStyle(
            color: Color(0xFF101D32), fontSize: 23, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(
            color: Color(0xFF667085), fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
