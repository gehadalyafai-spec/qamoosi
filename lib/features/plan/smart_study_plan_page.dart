import 'package:flutter/material.dart';

import '../../core/smart_study_plan.dart';

/// A guided, read-only dashboard. Actions use the existing lesson and practice
/// flows, so completion persists through the established repositories.
class SmartStudyPlanPage extends StatefulWidget {
  const SmartStudyPlanPage({
    super.key,
    required this.loadPlan,
    required this.onReviewCards,
    required this.onLearnCards,
    required this.onReviewMistakes,
    required this.onPractice,
  });

  final Future<SmartStudyPlan> Function() loadPlan;
  final Future<void> Function(List<String>) onReviewCards;
  final Future<void> Function(List<String>) onLearnCards;
  final Future<void> Function() onReviewMistakes;
  final Future<void> Function() onPractice;

  @override
  State<SmartStudyPlanPage> createState() => _SmartStudyPlanPageState();
}

class _SmartStudyPlanPageState extends State<SmartStudyPlanPage> {
  SmartStudyPlan? _plan;
  bool _loading = true;
  bool _working = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final next = await widget.loadPlan();
      if (!mounted) return;
      setState(() {
        _plan = next;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذّر تحميل خطة اليوم. أعد المحاولة.';
      });
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_working || _loading) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) await _refresh(silent: true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'تعذّر إكمال النشاط. حاول مرة أخرى.');
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF101D32);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5F1),
        appBar: AppBar(
          title: const Text('خطتي الذكية اليوم'),
          backgroundColor: const Color(0xFFF7F5F1),
          actions: [
            IconButton(
              key: const Key('smart_plan_refresh'),
              tooltip: 'تحديث الخطة',
              onPressed: _working || _loading ? null : _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: _loading && _plan == null
              ? const Center(child: CircularProgressIndicator())
              : _plan == null
                  ? Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                          color: Color(0xFF667085), size: 40),
                        const SizedBox(height: 13),
                        Text(_error ?? 'لا يمكن عرض الخطة حاليًا.'),
                        const SizedBox(height: 12),
                        FilledButton(
                          key: const Key('smart_plan_retry'),
                          onPressed: () => _refresh(),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ))
                  : RefreshIndicator(
                      onRefresh: _working
                          ? () async {}
                          : () => _refresh(silent: true),
                      child: _buildOverview(_plan!, navy),
                    ),
        ),
      ),
    );
  }

  Widget _buildOverview(SmartStudyPlan plan, Color navy) {
    const muted = Color(0xFF667085);
    const orange = Color(0xFFFF653B);
    const green = Color(0xFF21865B);
    return ListView(
      key: const Key('smart_plan_scroll'),
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 36),
      children: [
        Container(
          key: const Key('smart_plan_goal'),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [navy, Color(0xFF293D65)],
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
                Expanded(child: Text('رحلتك اليوم',
                  style: TextStyle(
                    color: Colors.white, fontSize: 19,
                    fontWeight: FontWeight.w800))),
              ]),
              const SizedBox(height: 16),
              Text(
                '${plan.todayLearned} من ${plan.dailyGoal} بطاقات',
                key: const Key('smart_plan_goal_progress'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 13),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: plan.todayFraction,
                  minHeight: 10,
                  color: const Color(0xFFFFB184),
                  backgroundColor: Colors.white24,
                ),
              ),
              const SizedBox(height: 13),
              Text(plan.goalMet
                  ? 'رائع! وصلت إلى هدفك اليوم. يمكنك مراجعة ما تعلّمته.'
                  : 'متبقي ${plan.remainingToday} بطاقات لتحقيق هدف اليوم.',
                key: const Key('smart_plan_goal_message'),
                style: const TextStyle(
                  color: Color(0xFFECF0F8), height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            _CountChip(
              icon: Icons.schedule_rounded,
              label: 'مستحقة: ${plan.dueCount}',
            ),
            _CountChip(
              icon: Icons.school_outlined,
              label: 'متقنة: ${plan.mastered}/${plan.totalCards}',
            ),
            _CountChip(
              icon: Icons.rule_rounded,
              label: 'أخطاء: ${plan.pendingPracticeMistakes}',
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 13),
          Text(_error!,
            key: const Key('smart_plan_error'),
            style: const TextStyle(
              color: Color(0xFFB94824), fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 25),
        const Text('ماذا تتعلّم الآن؟',
          style: TextStyle(
            color: navy, fontSize: 23, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('ابدأ بالمراجعة المستحقة، ثم أضف كلمات جديدة.',
          style: TextStyle(color: muted, height: 1.5)),
        const SizedBox(height: 15),
        _PlanTaskCard(
          cardKey: const Key('smart_plan_review_card'),
          icon: Icons.history_edu_rounded,
          tint: const Color(0xFFEAF3FF),
          iconColor: const Color(0xFF3166A4),
          heading: '1. المراجعة المستحقة',
          description: plan.dueCount == 0
              ? 'لا توجد بطاقات مستحقة الآن.'
              : 'لديك ${plan.dueCount} بطاقات مستحقة. ابدأ بالأقدم.',
          words: plan.dueCards.map((card) => card.word).toList(),
          buttonKey: const Key('smart_plan_review_button'),
          buttonLabel: 'راجع ${plan.dueCards.length} بطاقات',
          onPressed: plan.dueCards.isEmpty || _working
              ? null
              : () => _run(() => widget.onReviewCards(
                    plan.dueCards.map((card) => card.id).toList())),
          footer: plan.dueCount > plan.dueCards.length
              ? 'ستبقى ${plan.dueCount - plan.dueCards.length} بطاقات لجلسة المراجعة التالية.'
              : plan.dueCount == 0 && plan.nextScheduledReview != null
                  ? 'المراجعة القادمة: ${_dateLabel(plan.nextScheduledReview!)}'
                  : null,
        ),
        const SizedBox(height: 12),
        _PlanTaskCard(
          cardKey: const Key('smart_plan_new_card'),
          icon: Icons.menu_book_rounded,
          tint: const Color(0xFFFFF0E7),
          iconColor: orange,
          heading: '2. كلمات جديدة مناسبة لك',
          description: plan.goalMet
              ? 'أنجزت هدف اليوم؛ لا يلزم إضافة كلمات جديدة.'
              : plan.allCardsMastered
                  ? 'أتقنت جميع الكلمات المتاحة حاليًا.'
                  : plan.newCards.isEmpty
                      ? 'ابدأ بمراجعة بطاقاتك المستحقة أولًا.'
                      : 'من درس: ${plan.nextLesson ?? "المسار التعليمي"}.',
          words: plan.newCards.map((card) => card.word).toList(),
          buttonKey: const Key('smart_plan_new_button'),
          buttonLabel: 'تعلّم ${plan.newCards.length} كلمات',
          onPressed: plan.newCards.isEmpty || _working
              ? null
              : () => _run(() => widget.onLearnCards(
                    plan.newCards.map((card) => card.id).toList())),
        ),
        const SizedBox(height: 12),
        _PlanTaskCard(
          cardKey: const Key('smart_plan_mistakes_card'),
          icon: Icons.psychology_alt_rounded,
          tint: const Color(0xFFF2ECFF),
          iconColor: const Color(0xFF6857CE),
          heading: '3. ثبّت المفاهيم',
          description: plan.pendingPracticeMistakes == 0
              ? 'لا توجد أخطاء عملية معلّقة. اختبر فهمك بتدريب جديد.'
              : 'لديك ${plan.pendingPracticeMistakes} مواقف تحتاج مراجعة.',
          words: const [],
          buttonKey: const Key('smart_plan_mistakes_button'),
          buttonLabel: 'مراجعة أخطائي',
          onPressed: plan.pendingPracticeMistakes == 0 || _working
              ? null
              : () => _run(widget.onReviewMistakes),
          secondaryButtonKey: const Key('smart_plan_practice_button'),
          secondaryButtonLabel: 'تدريب عملي جديد',
          onSecondaryPressed: _working
              ? null
              : () => _run(widget.onPractice),
        ),
        const SizedBox(height: 15),
        if (plan.goalMet && plan.dueCount == 0 &&
            plan.pendingPracticeMistakes == 0)
          Container(
            key: const Key('smart_plan_completed'),
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F7ED),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(children: [
              Icon(Icons.verified_rounded, color: green),
              SizedBox(width: 10),
              Expanded(child: Text(
                'أنجزت هدف اليوم ولا توجد مراجعات مستحقة أو أخطاء معلّقة.',
                style: TextStyle(
                  color: navy, fontWeight: FontWeight.w700, height: 1.5))),
            ]),
          ),
      ],
    );
  }

  String _dateLabel(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    return '$day/$month • $hours:$minutes';
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE9E6EE)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 17, color: const Color(0xFF6857CE)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(
        color: Color(0xFF101D32), fontSize: 12,
        fontWeight: FontWeight.w700)),
    ]),
  );
}

class _PlanTaskCard extends StatelessWidget {
  const _PlanTaskCard({
    required this.cardKey,
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.heading,
    required this.description,
    required this.words,
    required this.buttonKey,
    required this.buttonLabel,
    required this.onPressed,
    this.footer,
    this.secondaryButtonKey,
    this.secondaryButtonLabel,
    this.onSecondaryPressed,
  });

  final Key cardKey;
  final IconData icon;
  final Color tint;
  final Color iconColor;
  final String heading;
  final String description;
  final List<String> words;
  final Key buttonKey;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final String? footer;
  final Key? secondaryButtonKey;
  final String? secondaryButtonLabel;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF101D32);
    const muted = Color(0xFF667085);
    return Container(
      key: cardKey,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7E5EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: tint, borderRadius: BorderRadius.circular(15)),
              child: Icon(icon, color: iconColor, size: 25),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(heading,
              style: const TextStyle(
                color: navy, fontSize: 17, fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 11),
          Text(description,
            style: const TextStyle(color: muted, height: 1.6)),
          if (words.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final word in words)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(10)),
                    child: Text(word,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: navy, fontWeight: FontWeight.w700,
                        fontSize: 12)),
                  ),
              ],
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: 10),
            Text(footer!,
              style: const TextStyle(color: muted, fontSize: 12)),
          ],
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: buttonKey,
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(buttonLabel),
              style: FilledButton.styleFrom(
                backgroundColor: navy,
                disabledBackgroundColor: const Color(0xFFDEE1E7),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          if (secondaryButtonKey != null &&
              secondaryButtonLabel != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: secondaryButtonKey,
                onPressed: onSecondaryPressed,
                child: Text(secondaryButtonLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
