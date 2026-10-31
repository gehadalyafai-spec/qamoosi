import 'package:flutter/material.dart';

/// Shows a single suggested lesson; the caller decides what to recommend.
class LearningPathCard extends StatelessWidget {
  const LearningPathCard({
    super.key,
    required this.lessonTitle,
    required this.levelLabel,
    required this.learned,
    required this.total,
    required this.onStart,
  }) : assert(total >= 0),
       assert(learned >= 0 && learned <= total);

  /// Null when every available lesson has been completed.
  final String? lessonTitle;
  final String? levelLabel;
  final int learned;
  final int total;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF101D32);
    const muted = Color(0xFF667085);
    const orange = Color(0xFFFF653B);

    if (lessonTitle == null) {
      return Container(
        key: const Key('learning_path_complete'),
        padding: const EdgeInsets.all(21),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7EF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD2EAD9)),
        ),
        child: const Row(children: [
          Icon(Icons.verified_rounded, color: Color(0xFF21865B), size: 36),
          SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('أكملت المسار الحالي', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: navy)),
              SizedBox(height: 6),
              Text('أتقنت جميع الكلمات المتاحة! واصل المراجعة لتثبيتها.',
                style: TextStyle(fontSize: 13, color: muted)),
            ]),
          ),
        ]),
      );
    }

    final remaining = total - learned;
    final progress = total == 0 ? 0.0 : learned / total;

    return Container(
      key: const Key('learning_path_card'),
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFEAE4F8)),
        boxShadow: const [BoxShadow(
          color: Color(0x090B1A33), blurRadius: 18, offset: Offset(0, 5),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.route_rounded, color: orange, size: 24),
          SizedBox(width: 9),
          Text('مسارك التعليمي', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800, color: navy)),
        ]),
        const SizedBox(height: 7),
        const Text('الدرس المناسب لك الآن', style: TextStyle(
          fontSize: 13, color: muted)),
        const SizedBox(height: 17),
        Text(lessonTitle!, style: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.w900, color: navy)),
        const SizedBox(height: 6),
        Text('المستوى: $levelLabel  ·  متبقي $remaining من $total بطاقات',
          style: const TextStyle(fontSize: 13, color: muted)),
        const SizedBox(height: 15),
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFF0EDF4),
            color: orange,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('learning_path_start'),
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(learned == 0 ? 'ابدأ الدرس المقترح' : 'أكمل الدرس المقترح'),
            style: FilledButton.styleFrom(
              backgroundColor: navy,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ]),
    );
  }
}
