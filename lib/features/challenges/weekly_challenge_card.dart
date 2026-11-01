import 'package:flutter/material.dart';

import '../../core/weekly_challenge.dart';

/// Compact home card. Only the target is saved; progress is read directly
/// from the learner's existing local daily study history.
class WeeklyChallengeCard extends StatelessWidget {
  const WeeklyChallengeCard({
    super.key,
    required this.challenge,
    required this.onGoalChanged,
    required this.onStart,
    required this.canStart,
  });

  final WeeklyChallenge challenge;
  final Future<void> Function(int goal) onGoalChanged;
  final Future<void> Function() onStart;
  final bool canStart;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF101D32);
    const purple = Color(0xFF6857CE);
    const muted = Color(0xFF5B6577);
    return Container(
      key: const Key('weekly_challenge_card'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFEAE6F5)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.calendar_month_rounded, color: purple, size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text('تحدي الأسبوع',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: navy,
                )),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            challenge.isComplete
                ? 'حققت هدفك الأسبوعي! يمكنك مواصلة المراجعة.'
                : 'تدرّب على كلمات مختلفة خلال الأسبوع بالوتيرة التي تناسبك.',
            key: const Key('weekly_challenge_message'),
            style: const TextStyle(color: muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '${challenge.completedCards} من ${challenge.goal} بطاقة',
                  key: const Key('weekly_challenge_count'),
                  style: const TextStyle(color: navy, fontSize: 19,
                    fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '${challenge.activeDays} أيام تعلم',
                key: const Key('weekly_active_days'),
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              key: const Key('weekly_challenge_progress'),
              value: challenge.progress,
              minHeight: 9,
              backgroundColor: const Color(0xFFECEAF5),
              color: const Color(0xFF6857CE),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'من الأحد إلى السبت • المتبقي: ${challenge.remainingCards}',
            key: const Key('weekly_challenge_remaining'),
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          const Text('اختر هدفك الأسبوعي',
            style: TextStyle(fontWeight: FontWeight.w700,
              fontSize: 13, color: navy)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 6,
            children: [
              for (final target in WeeklyChallenge.allowedGoals)
                ChoiceChip(
                  key: Key('weekly_goal_$target'),
                  label: Text('$target'),
                  selected: target == challenge.goal,
                  onSelected: (_) => onGoalChanged(target),
                  visualDensity: VisualDensity.compact,
                  selectedColor: const Color(0xFFE9E4FF),
                ),
            ],
          ),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('weekly_challenge_start'),
              onPressed: canStart ? onStart : null,
              icon: Icon(challenge.isComplete
                  ? Icons.check_circle_rounded : Icons.play_arrow_rounded),
              label: Text(challenge.isComplete
                  ? 'واصل تثبيت كلماتك'
                  : canStart
                      ? 'ابدأ جلسة الأسبوع'
                      : 'لا توجد بطاقات متاحة حاليًا'),
              style: FilledButton.styleFrom(
                backgroundColor: navy,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
