import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/code_lab_mistakes.dart';
import '../../core/section_quiz_stats.dart';
import 'code_lab_exercises.dart';

/// Interactive offline coding exercises. No source code is evaluated:
/// users choose a statement or assemble a sequence of authored steps.
class CodeLabPage extends StatefulWidget {
  const CodeLabPage({
    super.key,
    this.catalog = codeLabCatalog,
    this.reviewMistakes = false,
  });

  static const statsId = 'code_lab';
  final List<CodeLabExercise> catalog;
  final bool reviewMistakes;

  @override
  State<CodeLabPage> createState() => _CodeLabPageState();
}

class _CodeLabPageState extends State<CodeLabPage> {
  static const autoAdvanceDelay = Duration(milliseconds: 850);
  final selectedSteps = <int>[];
  final answers = <String, bool>{};
  List<CodeLabExercise> questions = const [];
  SectionQuizStats stats = const SectionQuizStats();
  CodeLabMistakes mistakes = CodeLabMistakes.empty;
  Timer? autoAdvance;
  int index = 0;
  int correct = 0;
  bool ready = false;
  bool answered = false;
  bool answerWasCorrect = false;
  bool saving = false;
  bool finished = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    autoAdvance?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    autoAdvance?.cancel();
    final prefs = await SharedPreferences.getInstance();
    final latest = SectionQuizStats.fromPreferences(
      prefs, CodeLabPage.statsId);
    final pending = CodeLabMistakes.fromPreferences(
      prefs, catalog: widget.catalog);
    if (!mounted) return;
    setState(() {
      stats = latest;
      mistakes = pending;
      questions = widget.reviewMistakes
          ? pending.pendingExercises(catalog: widget.catalog)
          : buildCodeLabRound(
              completedAttempts: latest.attempts,
              catalog: widget.catalog,
            );
      index = 0;
      correct = 0;
      answered = false;
      answerWasCorrect = false;
      saving = false;
      finished = false;
      ready = true;
      selectedSteps.clear();
      answers.clear();
    });
  }

  void _evaluate(bool isCorrect) {
    if (!ready || answered || saving || finished) return;
    autoAdvance?.cancel();
    setState(() {
      answered = true;
      answers[questions[index].id] = isCorrect;
      answerWasCorrect = isCorrect;
      if (isCorrect) correct++;
    });
    if (isCorrect) {
      autoAdvance = Timer(autoAdvanceDelay, () {
        if (mounted) _advance();
      });
    }
  }

  void _selectStep(int stepIndex) {
    if (answered || finished || selectedSteps.contains(stepIndex)) return;
    setState(() => selectedSteps.add(stepIndex));
  }

  void _undoStep() {
    if (answered || selectedSteps.isEmpty) return;
    setState(() => selectedSteps.removeLast());
  }

  Future<void> _advance() async {
    if (!answered || saving || finished) return;
    autoAdvance?.cancel();
    if (index == questions.length - 1) {
      await _finish();
      return;
    }
    setState(() {
      index++;
      answered = false;
      answerWasCorrect = false;
      selectedSteps.clear();
    });
  }

  Future<void> _finish() async {
    if (saving || finished) return;
    setState(() => saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      // Save mistakes independently; applying the same answers twice is safe.
      final pending = await CodeLabMistakes.recordRound(
        prefs, answers, catalog: widget.catalog);
      final result = widget.reviewMistakes
          ? stats
          : await SectionQuizStats.record(
              prefs, CodeLabPage.statsId, correct);
      if (!mounted) return;
      setState(() {
        stats = result;
        mistakes = pending;
        finished = true;
        saving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذّر حفظ نتيجة مختبر الكود. حاول مرة أخرى.'),
        ),
      );
    }
  }

  Widget _codeBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 19),
      decoration: BoxDecoration(
        color: const Color(0xFF16243C),
        borderRadius: BorderRadius.circular(18),
      ),
      child: SelectableText(
        text,
        key: const Key('code_lab_snippet'),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 15,
          height: 1.6,
          color: Color(0xFFF5F4FF),
        ),
      ),
    );
  }

  Widget _missingLine(CodeLabExercise task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _codeBox(task.snippet),
        const SizedBox(height: 18),
        const Text('اختر السطر الصحيح:',
          style: TextStyle(
            color: Color(0xFF101D32), fontWeight: FontWeight.w800,
            fontSize: 16)),
        const SizedBox(height: 10),
        for (var i = 0; i < task.options.length; i++) ...[
          OutlinedButton(
            key: Key('code_option_$i'),
            onPressed: answered ? null : () =>
                _evaluate(task.options[i] == task.correctAnswer),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              backgroundColor: answered &&
                      task.options[i] == task.correctAnswer
                  ? const Color(0xFFE8F4E7) : Colors.white,
              foregroundColor: const Color(0xFF101D32),
              side: const BorderSide(color: Color(0xFFDFDAEF)),
              padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(task.options[i],
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontFamily: 'monospace', fontSize: 14)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _orderedSteps(CodeLabExercise task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('ترتيبك الحالي:',
          style: TextStyle(
            color: Color(0xFF101D32), fontWeight: FontWeight.w800,
            fontSize: 16)),
        const SizedBox(height: 9),
        Container(
          key: const Key('code_selected_order'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0EDFA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: selectedSteps.isEmpty
              ? const Text('اضغط على الخطوات بالترتيب الصحيح',
                  style: TextStyle(color: Color(0xFF667085)))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < selectedSteps.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Text(
                          '${i + 1}. ${task.steps[selectedSteps[i]]}',
                          key: Key('code_selected_step_$i'),
                          style: const TextStyle(
                            color: Color(0xFF101D32),
                            fontWeight: FontWeight.w700,
                            height: 1.5),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          OutlinedButton.icon(
            key: const Key('code_undo_step'),
            onPressed: answered || selectedSteps.isEmpty ? null : _undoStep,
            icon: const Icon(Icons.undo_rounded, size: 19),
            label: const Text('تراجع'),
          ),
          const SizedBox(width: 8),
          Text(
            '${selectedSteps.length} / ${task.steps.length} خطوات',
            style: const TextStyle(
              color: Color(0xFF667085), fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        const Text('الخطوات المتاحة:',
          style: TextStyle(
            color: Color(0xFF101D32), fontWeight: FontWeight.w800,
            fontSize: 16)),
        const SizedBox(height: 10),
        for (final stepIndex in task.shuffledStepIndices) ...[
          OutlinedButton(
            key: Key('code_step_$stepIndex'),
            onPressed: answered || selectedSteps.contains(stepIndex)
                ? null : () => _selectStep(stepIndex),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerRight,
              foregroundColor: const Color(0xFF101D32),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFDFDAEF)),
              padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(task.steps[stepIndex],
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 14, height: 1.5)),
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        FilledButton.icon(
          key: const Key('code_check_order'),
          onPressed: answered ||
                  selectedSteps.length != task.steps.length
              ? null
              : () => _evaluate(task.matchesOrderedSteps(selectedSteps)),
          icon: const Icon(Icons.fact_check_rounded),
          label: const Text('تحقق من الترتيب'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6857CE),
            padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
      ],
    );
  }

  Widget _feedback(CodeLabExercise task) {
    if (!answered) return const SizedBox.shrink();
    return Container(
      key: const Key('code_lab_feedback'),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: answerWasCorrect
            ? const Color(0xFFE7F5E8) : const Color(0xFFFFF0E8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(answerWasCorrect
                ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: answerWasCorrect
                  ? const Color(0xFF21865B)
                  : const Color(0xFFB94824)),
            const SizedBox(width: 9),
            Text(answerWasCorrect
                ? 'إجابة صحيحة!' : 'راجع الحل الصحيح',
              key: const Key('code_lab_feedback_title'),
              style: const TextStyle(
                color: Color(0xFF101D32),
                fontSize: 17, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 9),
          if (!answerWasCorrect) ...[
            Text(task.kind == CodeLabKind.missingLine
                ? 'السطر الصحيح: ${task.correctAnswer}'
                : 'الترتيب الصحيح:',
              style: const TextStyle(
                color: Color(0xFF101D32),
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            if (task.kind == CodeLabKind.orderSteps)
              for (var i = 0; i < task.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text('${i + 1}. ${task.steps[i]}',
                    style: const TextStyle(
                      color: Color(0xFF101D32), height: 1.5)),
                ),
            const SizedBox(height: 8),
          ],
          Text(task.explanation,
            key: const Key('code_lab_explanation'),
            style: const TextStyle(
              color: Color(0xFF101D32), height: 1.6)),
          const SizedBox(height: 8),
          Text('مصطلح اليوم: ${task.term} — ${task.translation}',
            key: const Key('code_lab_term'),
            style: const TextStyle(
              color: Color(0xFF6857CE),
              fontWeight: FontWeight.w800)),
          if (!answerWasCorrect) ...[
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('code_next'),
              onPressed: saving ? null : _advance,
              child: Text(index == questions.length - 1
                  ? 'شاهد النتيجة' : 'السؤال التالي'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _result() {
    final pending = mistakes.pendingCount;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded,
              size: 62, color: Color(0xFF6857CE)),
            const SizedBox(height: 13),
            Text(widget.reviewMistakes
                ? 'اكتملت مراجعة أخطاء المختبر'
                : 'اكتملت جلسة مختبر الكود',
              style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900,
                color: Color(0xFF101D32)),
              textAlign: TextAlign.center),
            const SizedBox(height: 14),
            Text('نتيجتك: $correct من ${questions.length}',
              key: const Key('code_lab_result'),
              style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: Color(0xFF101D32))),
            const SizedBox(height: 9),
            if (!widget.reviewMistakes)
              Text(
                'أفضل نتيجة: ${stats.bestScore} من 6 • '
                'محاولات مكتملة: ${stats.attempts}',
                key: const Key('code_lab_best'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF667085))),
            const SizedBox(height: 9),
            Text(
              pending == 0
                  ? 'لا توجد أخطاء متبقية للمراجعة'
                  : 'تمارين تحتاج مراجعة: $pending',
              key: const Key('code_lab_pending'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF667085))),
            const SizedBox(height: 21),
            if (!widget.reviewMistakes || pending > 0)
              FilledButton.icon(
                key: const Key('code_lab_restart'),
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(widget.reviewMistakes
                    ? 'مراجعة الأخطاء المتبقية'
                    : 'تحدٍّ جديد'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6857CE)),
              ),
            const SizedBox(height: 9),
            TextButton(
              key: const Key('code_lab_back'),
              onPressed: () => Navigator.pop(context),
              child: const Text('العودة إلى التحديات'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.reviewMistakes
            ? 'مراجعة أخطاء المختبر' : 'مختبر الكود')),
        body: !ready
            ? const Center(child: CircularProgressIndicator())
            : questions.isEmpty
                ? Center(child: Text(widget.reviewMistakes
                    ? 'لا توجد أخطاء تحتاج مراجعة'
                    : 'لا توجد تمارين متاحة حاليًا'))
                : finished
                    ? _result()
                    : SafeArea(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(19, 17, 19, 32),
                          children: [
                            Row(children: [
                              Expanded(child: Text(
                                '${widget.reviewMistakes ? 'المراجعة' : 'التمرين'} ${index + 1} من ${questions.length}',
                                key: const Key('code_lab_question_count'),
                                style: const TextStyle(
                                  color: Color(0xFF101D32),
                                  fontWeight: FontWeight.w800))),
                              Text('الصحيح: $correct',
                                key: const Key('code_lab_live_score'),
                                style: const TextStyle(
                                  color: Color(0xFF6857CE),
                                  fontWeight: FontWeight.w700)),
                            ]),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: (index + 1) / questions.length,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFE6E4EF),
                              color: const Color(0xFF6857CE)),
                            const SizedBox(height: 22),
                            Text(
                              questions[index].kind == CodeLabKind.missingLine
                                  ? 'أكمل السطر الناقص'
                                  : 'رتّب الخطوات',
                              style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w800,
                                color: Color(0xFF6857CE))),
                            const SizedBox(height: 7),
                            Text(questions[index].title,
                              style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w900,
                                color: Color(0xFF101D32))),
                            const SizedBox(height: 9),
                            Text(questions[index].prompt,
                              style: const TextStyle(
                                color: Color(0xFF667085),
                                fontSize: 15, height: 1.6)),
                            const SizedBox(height: 18),
                            if (questions[index].kind ==
                                CodeLabKind.missingLine)
                              _missingLine(questions[index])
                            else
                              _orderedSteps(questions[index]),
                            if (answered) ...[
                              const SizedBox(height: 17),
                              _feedback(questions[index]),
                            ],
                            if (saving) ...[
                              const SizedBox(height: 13),
                              const Center(
                                child: CircularProgressIndicator()),
                            ],
                          ],
                        ),
                      ),
      ),
    );
  }
}
