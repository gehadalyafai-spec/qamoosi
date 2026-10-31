import 'package:flutter/material.dart';

import '../../data/word_insights.dart';

/// Common lesson/search presentation of offline vocabulary explanations.
class WordInsightDetails extends StatelessWidget {
  const WordInsightDetails({
    super.key,
    required this.insight,
    this.compact = false,
  });

  final WordInsight insight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF101D32);
    const muted = Color(0xFF667085);
    const orange = Color(0xFFFF653B);
    final padding = compact ? 13.0 : 16.0;

    return Column(
      key: const Key('word_insight_details'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F0FF),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.lightbulb_outline_rounded,
                  color: Color(0xFF6857CE), size: 20),
                SizedBox(width: 7),
                Text('شرح مبسط', style: TextStyle(
                  color: navy, fontSize: 15, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 8),
              Text(insight.explanation, style: const TextStyle(
                color: navy, fontSize: 14, height: 1.6)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F6F3),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.terminal_rounded, color: Color(0xFF21865B), size: 20),
                SizedBox(width: 7),
                Text('من واقع المشاريع', style: TextStyle(
                  color: navy, fontSize: 15, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 8),
              Text(insight.projectUse, style: const TextStyle(
                color: navy, fontSize: 14, height: 1.6)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Row(children: [
          Icon(Icons.psychology_alt_outlined, size: 20, color: orange),
          SizedBox(width: 7),
          Text('سؤال للتفكير', style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w800, color: navy)),
        ]),
        const SizedBox(height: 7),
        Text(insight.practiceQuestion, style: const TextStyle(
          color: muted, fontSize: 14, height: 1.6)),
      ],
    );
  }
}
