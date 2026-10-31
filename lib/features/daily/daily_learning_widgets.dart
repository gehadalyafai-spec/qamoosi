import 'package:flutter/material.dart';
import '../../core/daily_learning_progress.dart';

class DailyGoalCard extends StatelessWidget {
  const DailyGoalCard({
    super.key,
    required this.progress,
    required this.now,
    required this.onGoalChanged,
  });

  final DailyLearningProgress progress;
  final DateTime now;
  final ValueChanged<int> onGoalChanged;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF101D32);
    const orange = Color(0xFFFF653B);
    final today = progress.countOn(now);
    final remaining = progress.remainingOn(now);
    return Container(
      key: const Key('daily_goal_card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0EBE8)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEE6),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.local_fire_department_rounded,
              color: orange, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('هدفك اليوم', style: TextStyle(
              color: navy, fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          PopupMenuButton<int>(
            key: const Key('daily_goal_selector'),
            tooltip: 'تعديل الهدف اليومي',
            initialValue: progress.dailyGoal,
            onSelected: onGoalChanged,
            itemBuilder: (context) => [
              for (final goal in DailyLearningProgress.allowedGoals)
                PopupMenuItem(value: goal, child: Text('$goal بطاقات يوميًا')),
            ],
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('تعديل الهدف', style: TextStyle(
                  fontSize: 13, color: Color(0xFF6857CE))),
                SizedBox(width: 4),
                Icon(Icons.tune_rounded, size: 19, color: Color(0xFF6857CE)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 15),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$today من ${progress.dailyGoal} بطاقات',
            style: const TextStyle(fontSize: 17,
              fontWeight: FontWeight.w800, color: navy)),
          Text('${(progress.fractionOn(now) * 100).round()}%',
            style: const TextStyle(fontSize: 14, color: orange,
              fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 11),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: progress.fractionOn(now),
            minHeight: 9,
            color: orange,
            backgroundColor: const Color(0xFFF1EDEB),
          ),
        ),
        const SizedBox(height: 12),
        Text(remaining == 0
            ? 'أكملت هدفك اليوم! استمر في تثبيت الكلمات.'
            : 'باقي $remaining بطاقة لتحقيق هدفك اليوم.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF667085))),
      ]),
    );
  }
}

class WeeklyLearningPanel extends StatelessWidget {
  const WeeklyLearningPanel({
    super.key,
    required this.progress,
    required this.now,
  });

  final DailyLearningProgress progress;
  final DateTime now;

  static const dayNames = <String>[
    'إثن', 'ثلث', 'أرب', 'خمس', 'جمع', 'سبت', 'أحد',
  ];

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF101D32);
    const orange = Color(0xFFFF653B);
    const muted = Color(0xFF667085);
    final local = now.toLocal();
    final today = DateTime(local.year, local.month, local.day);
    final lastWeek = [
      for (var i = 6; i >= 0; i--)
        DateTime(today.year, today.month, today.day - i),
    ];
    return Container(
      key: const Key('weekly_activity_panel'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.calendar_month_rounded, color: orange),
          SizedBox(width: 9),
          Expanded(child: Text('نشاط آخر 7 أيام', style: TextStyle(
            color: navy, fontSize: 18, fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 7),
        const Text('كل بطاقة تُحتسب مرة واحدة خلال اليوم',
          style: TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 21),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final day in lastWeek)
              Expanded(
                child: Column(children: [
                  Text('${progress.countOn(day)}', style: const TextStyle(
                    fontSize: 12, color: navy, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 58,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: (progress.fractionOn(day) * 0.9 + 0.1)
                            .clamp(0.1, 1.0).toDouble(),
                        child: Container(
                          width: 23,
                          decoration: BoxDecoration(
                            color: progress.countOn(day) == 0
                                ? const Color(0xFFE6E7ED)
                                : orange,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(dayNames[day.weekday - 1],
                    style: const TextStyle(fontSize: 11, color: muted)),
                ]),
              ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 15),
        Row(children: [
          const Icon(Icons.local_fire_department_rounded,
            color: orange, size: 21),
          const SizedBox(width: 7),
          Text('سلسلة التعلم: ${progress.streakOn(now)} يوم',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
              color: navy)),
          const Spacer(),
          Text('${progress.activeDays} أيام نشاط',
            style: const TextStyle(color: muted, fontSize: 12)),
        ]),
      ]),
    );
  }
}
