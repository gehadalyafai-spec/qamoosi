import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/quiz_difficulty.dart';
import '../../core/section_quiz_stats.dart';

/// One short, approachable entry point instead of three more home cards.
/// Difficulty results are saved separately from legacy and topic quizzes.
class QuizDifficultyPicker extends StatefulWidget {
  const QuizDifficultyPicker({
    super.key,
    required this.onStart,
    this.onCodeLab,
  });

  final Future<void> Function(QuizDifficulty) onStart;
  /// Optional for backward compatibility with existing challenges/tests.
  final Future<void> Function()? onCodeLab;

  @override
  State<QuizDifficultyPicker> createState() => _QuizDifficultyPickerState();
}

class _QuizDifficultyPickerState extends State<QuizDifficultyPicker> {
  Map<String, SectionQuizStats> results = {};
  bool opening = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => results = SectionQuizStats.allFromPreferences(prefs));
  }

  Future<void> _open(QuizDifficulty difficulty) async {
    if (opening) return;
    setState(() => opening = true);
    try {
      await widget.onStart(difficulty);
    } finally {
      if (mounted) {
        setState(() => opening = false);
        await _refresh();
      }
    }
  }

  Future<void> _openCodeLab() async {
    final callback = widget.onCodeLab;
    if (opening || callback == null) return;
    setState(() => opening = true);
    try {
      await callback();
    } finally {
      if (mounted) {
        setState(() => opening = false);
        await _refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF101D32);
    const purple = Color(0xFF6857CE);
    const accent = [
      Color(0xFFE8F5EE),
      Color(0xFFEFE8FF),
      Color(0xFFFFEEE4),
    ];
    const icons = [
      Icons.translate_rounded,
      Icons.work_outline_rounded,
      Icons.code_rounded,
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('اختر مستوى الاختبار')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
            children: [
              const Text('تحديات الإنجليزية التقنية',
                style: TextStyle(
                  color: navy, fontSize: 23, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text(
                'اختر طريقة التعلّم المناسبة لك. كل اختبار ستة أسئلة، '
                'ودرجة كل مستوى تُحفظ بشكل مستقل.',
                style: TextStyle(
                  color: Color(0xFF667085), height: 1.6, fontSize: 14)),
              const SizedBox(height: 20),
              for (var i = 0; i < QuizDifficulty.values.length; i++) ...[
                Builder(builder: (context) {
                  final difficulty = QuizDifficulty.values[i];
                  final stats = results[difficulty.storageId] ??
                      const SectionQuizStats();
                  return Material(
                    color: Colors.white,
                    clipBehavior: Clip.antiAlias,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      key: Key('quiz_level_${difficulty.name}'),
                      onTap: opening ? null : () => _open(difficulty),
                      child: Padding(
                        padding: const EdgeInsets.all(17),
                        child: Row(children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: accent[i],
                              borderRadius: BorderRadius.circular(17)),
                            child: Icon(icons[i], color: navy, size: 29),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(difficulty.label,
                                  style: const TextStyle(
                                    color: navy, fontSize: 19,
                                    fontWeight: FontWeight.w900)),
                                const SizedBox(height: 6),
                                Text(difficulty.description,
                                  style: const TextStyle(
                                    color: Color(0xFF667085),
                                    height: 1.5, fontSize: 12)),
                                if (stats.attempts > 0) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'محاولات ${stats.attempts} • '
                                    'أفضل درجة ${stats.bestScore}/6',
                                    key: Key('quiz_level_stats_${difficulty.name}'),
                                    style: const TextStyle(
                                      color: purple,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                                ],
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 15, color: purple),
                        ]),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],
              if (widget.onCodeLab != null) ...[
                const SizedBox(height: 6),
                const Divider(color: Color(0xFFE4E0F0)),
                const SizedBox(height: 14),
                const Text('طبّق ما تعلمته',
                  style: TextStyle(
                    color: navy, fontSize: 20,
                    fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Material(
                  color: const Color(0xFF16243C),
                  clipBehavior: Clip.antiAlias,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    key: const Key('open_code_lab'),
                    onTap: opening ? null : _openCodeLab,
                    child: Padding(
                      padding: const EdgeInsets.all(17),
                      child: Row(children: [
                        Container(
                          height: 54, width: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFF33456B),
                            borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.terminal_rounded,
                            color: Colors.white, size: 29),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('مختبر الكود التفاعلي',
                              style: TextStyle(
                                color: Colors.white, fontSize: 18,
                                fontWeight: FontWeight.w900)),
                            const SizedBox(height: 5),
                            const Text('أكمل سطرًا ناقصًا ورتّب خطوات البرمجة',
                              style: TextStyle(
                                color: Color(0xFFD5DDF0),
                                fontSize: 12, height: 1.5)),
                            if ((results['code_lab']?.attempts ?? 0) > 0) ...[
                              const SizedBox(height: 8),
                              Text(
                                'محاولات ${results['code_lab']!.attempts} • '
                                'أفضل درجة ${results['code_lab']!.bestScore}/6',
                                key: const Key('code_lab_picker_stats'),
                                style: const TextStyle(
                                  color: Color(0xFFD4C8FF),
                                  fontWeight: FontWeight.w700, fontSize: 12)),
                            ],
                          ],
                        )),
                        const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 16),
                      ]),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              const Text(
                'في المتوسط والمتقدم يظهر نطق المصطلح بعد الإجابة، '
                'حتى يكون السؤال اختبار فهم حقيقيًا.',
                style: TextStyle(
                  color: Color(0xFF667085), fontSize: 12,
                  height: 1.6, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ),
    );
  }
}
