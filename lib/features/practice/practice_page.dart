import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'practice_questions.dart';
import 'practice_stats.dart';
import 'practice_mistakes.dart';

/// A separate offline assessment of practical understanding rather than
/// translation recall. An attempt is recorded only after the final answer.
class PracticePage extends StatefulWidget {
  const PracticePage({super.key, this.reviewMistakes = false});

  final bool reviewMistakes;

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  final ScrollController _scrollController = ScrollController(keepScrollOffset: false);
  List<PracticeQuestion> _questions = const [];
  PracticeStats _stats = const PracticeStats();
  PracticeMistakes _mistakes = PracticeMistakes.empty;
  int _index = 0;
  int _correct = 0;
  int? _selected;
  bool _loading = true;
  bool _saving = false;
  bool _answerCommitted = false;
  bool _finished = false;
  String? _loadError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final stats = PracticeStats.fromPreferences(prefs);
      final mistakes = PracticeMistakes.fromPreferences(prefs);
      final questions = widget.reviewMistakes
          ? mistakes.prioritized()
          : buildPracticeSession(stats.attempts);
      if (!mounted) {
        return;
      }
      setState(() {
        _stats = stats;
        _mistakes = mistakes;
        _questions = questions;
        _index = 0;
        _correct = 0;
        _selected = null;
        _finished = false;
        _answerCommitted = false;
        _saving = false;
        _saveError = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadError = 'تعذّر تحميل التدريب. حاول مجددًا.';
      });
    }
  }

  void _answer(int choice) {
    if (_loading || _finished || _selected != null) {
      return;
    }
    final question = _questions[_index];
    if (choice < 0 || choice >= question.options.length) {
      return;
    }
    setState(() {
      _selected = choice;
      if (question.isCorrect(choice)) {
        _correct++;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _next() async {
    if (_selected == null || _saving || _finished) {
      return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      // A retry of final-score persistence must not count the same mistake
      // twice. We only commit one answer per question.
      if (!_answerCommitted) {
        final prefs = await SharedPreferences.getInstance();
        final question = _questions[_index];
        final ledger = await PracticeMistakes.recordAnswer(
          prefs,
          questionId: question.id,
          wasCorrect: question.isCorrect(_selected!),
        );
        if (!mounted) {
          return;
        }
        _mistakes = ledger;
        _answerCommitted = true;
      }

      if (_index + 1 < _questions.length) {
        setState(() {
          _index++;
          _selected = null;
          _answerCommitted = false;
          _saveError = null;
        });
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
        return;
      }

      if (!widget.reviewMistakes) {
        final result = await PracticeStats.record(_correct);
        if (!mounted) {
          return;
        }
        _stats = result;
      }
      if (mounted) {
        setState(() => _finished = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saveError = 'تعذّر حفظ الإجابة. حاول مجددًا.');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _openMistakeReview() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => const PracticePage(reviewMistakes: true),
      ),
    );
    if (!mounted) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _mistakes = PracticeMistakes.fromPreferences(prefs);
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر تحديث عدد الأخطاء')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF101D32);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.reviewMistakes
              ? 'مراجعة أخطائي'
              : 'تدريب فهم المصطلحات'),
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null || _questions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          key: const Key('practice_empty_state'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _loadError == null && widget.reviewMistakes
                                  ? Icons.verified_rounded
                                  : Icons.error_outline_rounded,
                              size: 52,
                              color: _loadError == null && widget.reviewMistakes
                                  ? const Color(0xFF21865B)
                                  : const Color(0xFF667085),
                            ),
                            const SizedBox(height: 12),
                            Text(_loadError ??
                                (widget.reviewMistakes
                                    ? 'لا توجد أخطاء معلّقة للمراجعة'
                                    : 'لا تتوفر أسئلة حاليًا')),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _loadError != null
                                  ? _prepare
                                  : () => Navigator.pop(context),
                              child: Text(
                                _loadError != null
                                    ? 'إعادة المحاولة'
                                    : 'العودة للرئيسية',
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _finished
                      ? _buildResult(navy)
                      : _buildQuestion(navy),
        ),
      ),
    );
  }

  Widget _buildQuestion(Color navy) {
    final question = _questions[_index];
    final selected = _selected;
    const orange = Color(0xFFFF653B);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'الموقف ${_index + 1} من ${_questions.length}',
            style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800,
              color: Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (_index + 1) / _questions.length,
            minHeight: 8,
            borderRadius: BorderRadius.circular(12),
            color: orange,
            backgroundColor: const Color(0xFFEAE8EF),
          ),
          if (!widget.reviewMistakes && _stats.attempts > 0) ...[
            const SizedBox(height: 9),
            Text(
              'أفضل نتيجة سابقة: ${_stats.bestScore} من 6',
              style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
            ),
          ],
          if (widget.reviewMistakes) ...[
            const SizedBox(height: 9),
            Text(
              'مرات الخطأ السابقة: ${_mistakes.mistakesFor(question.id)}',
              key: const Key('practice_mistake_priority'),
              style: const TextStyle(
                color: Color(0xFF6857CE),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              key: const Key('practice_question_scroll'),
              controller: _scrollController,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101D32),
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.psychology_rounded,
                          color: Color(0xFFFFB184)),
                        SizedBox(width: 9),
                        Text('فكّر كأنك تطوّر التطبيق',
                          style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 17),
                      Text(
                        question.prompt,
                        key: const Key('practice_prompt'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18, height: 1.65,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text('اختر الحل الأنسب',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                for (var i = 0; i < question.options.length; i++) ...[
                  OutlinedButton(
                    key: Key('practice_choice_$i'),
                    onPressed: selected == null ? () => _answer(i) : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 17, horizontal: 15),
                      disabledForegroundColor: navy,
                      alignment: Alignment.centerRight,
                      backgroundColor: selected != null &&
                              question.correctIndex == i
                          ? const Color(0xFFE2F5E8)
                          : selected == i
                              ? const Color(0xFFFFE4DE)
                              : Colors.white,
                      side: BorderSide(
                        color: selected != null && question.correctIndex == i
                            ? const Color(0xFF21865B)
                            : selected == i
                                ? const Color(0xFFCF4B32)
                                : const Color(0xFFDFE3EA),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(
                          question.options[i],
                          style: const TextStyle(fontSize: 15, height: 1.45),
                        )),
                        if (selected != null && i == question.correctIndex)
                          const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF21865B), size: 21),
                        if (selected == i && i != question.correctIndex)
                          const Icon(Icons.cancel_rounded,
                            color: Color(0xFFCF4B32), size: 21),
                      ],
                    ),
                  ),
                  const SizedBox(height: 9),
                ],
                if (selected != null) ...[
                  const SizedBox(height: 11),
                  Container(
                    key: const Key('practice_feedback'),
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F3FF),
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.isCorrect(selected)
                              ? 'إجابة صحيحة!'
                              : 'الإجابة الأنسب: ${question.options[question.correctIndex]}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: navy,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(question.explanation,
                          style: TextStyle(
                            color: navy, fontSize: 14, height: 1.6)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_saveError != null) ...[
            Text(_saveError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
          ],
          if (selected != null)
            FilledButton.icon(
              key: const Key('practice_next'),
              onPressed: _saving ? null : _next,
              style: FilledButton.styleFrom(
                backgroundColor: orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(
                _saving
                    ? 'جارٍ حفظ الإجابة...'
                    : _index + 1 == _questions.length
                        ? 'عرض النتيجة'
                        : 'الموقف التالي',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResult(Color navy) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          key: const Key('practice_result'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium_rounded,
              size: 73, color: Color(0xFFFF653B)),
            const SizedBox(height: 16),
            Text(widget.reviewMistakes
                ? 'أنهيت مراجعة أخطائك!'
                : 'أكملت التدريب العملي!',
              style: TextStyle(
                color: navy, fontSize: 23, fontWeight: FontWeight.w900)),
            const SizedBox(height: 13),
            Text('نتيجتك: $_correct من ${_questions.length}',
              style: TextStyle(
                color: navy, fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            if (widget.reviewMistakes) ...[
              Text('مواقف تحتاج مراجعة: ${_mistakes.pendingCount}',
                key: const Key('practice_remaining_mistakes'),
                style: const TextStyle(color: Color(0xFF667085))),
            ] else ...[
              Text('أفضل نتيجة: ${_stats.bestScore} من 6',
                style: const TextStyle(color: Color(0xFF667085))),
              const SizedBox(height: 5),
              Text('التدريبات المكتملة: ${_stats.attempts}',
                style: const TextStyle(color: Color(0xFF667085))),
              const SizedBox(height: 8),
              Text('مواقف تحتاج مراجعة: ${_mistakes.pendingCount}',
                key: const Key('practice_remaining_mistakes'),
                style: const TextStyle(color: Color(0xFF667085))),
            ],
            const SizedBox(height: 24),
            if (widget.reviewMistakes && _mistakes.pendingCount == 0)
              const Text('ممتاز! لا توجد أخطاء متبقية حاليًا.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF21865B),
                  fontWeight: FontWeight.w800)),
            if (!widget.reviewMistakes || _mistakes.pendingCount > 0) ...[
              FilledButton.icon(
                key: const Key('practice_retry'),
                onPressed: _prepare,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(widget.reviewMistakes
                    ? 'مراجعة الأخطاء المتبقية'
                    : 'تدريب جديد'),
              ),
              const SizedBox(height: 9),
            ],
            if (!widget.reviewMistakes && _mistakes.pendingCount > 0) ...[
              OutlinedButton.icon(
                key: const Key('practice_review_mistakes'),
                onPressed: _openMistakeReview,
                icon: const Icon(Icons.rule_rounded),
                label: const Text('مراجعة أخطائي الآن'),
              ),
              const SizedBox(height: 9),
            ],
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    );
  }

}
