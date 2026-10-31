import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui';
import 'core/review_scheduler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QamoosiApp());
}

class QamoosiApp extends StatelessWidget {
  const QamoosiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'قاموسي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6554C0)),
        scaffoldBackgroundColor: const Color(0xFFF7F5F1),
      ),
      home: const HomePage(),
    );
  }
}

class CardEntry {
  final String id;
  final String word;
  final String pronunciation;
  final String translation;
  final String example;

  const CardEntry(this.id, this.word, this.pronunciation, this.translation, this.example);
}

class Lesson {
  final String title;
  final List<CardEntry> cards;
  const Lesson(this.title, this.cards);
}

const lessons = <Lesson>[
  Lesson('أساسيات البرمجة', [
    CardEntry('variable', 'Variable', 'ڤيريَبُل', 'متغير', 'int count = 1;'),
    CardEntry('constant', 'Constant', 'كونستَنت', 'ثابت', 'const appName = "قاموسي";'),
    CardEntry('function', 'Function', 'فانكشن', 'دالة', 'int add(int a, int b) => a + b;'),
    CardEntry('parameter', 'Parameter', 'باراميتر', 'معامل الدالة', 'void greet(String name) {}'),
    CardEntry('return', 'Return', 'ريتيرن', 'إرجاع قيمة', 'return total;'),
  ]),
  Lesson('الأخطاء والتطوير', [
    CardEntry('bug', 'Bug', 'بَغ', 'خلل برمجي', 'Fix the bug.'),
    CardEntry('debug', 'Debug', 'ديبَغ', 'تصحيح الأخطاء', 'flutter run --debug'),
    CardEntry('syntax', 'Syntax', 'سينتاكس', 'قواعد الصياغة البرمجية', 'Syntax error'),
    CardEntry('build', 'Build', 'بيلد', 'بناء التطبيق', 'flutter build apk'),
    CardEntry('release', 'Release', 'ريليس', 'إصدار للتوزيع', 'flutter build apk --release'),
  ]),
  Lesson('Git وGitHub', [
    CardEntry('repository', 'Repository', 'ريبوزيتوري', 'مستودع المشروع', 'git clone URL'),
    CardEntry('branch', 'Branch', 'برانش', 'فرع المشروع', 'git branch development'),
    CardEntry('commit', 'Commit', 'كومِت', 'تسجيل تغييرات', 'git commit -m "update"'),
    CardEntry('push', 'Push', 'بُش', 'رفع التغييرات', 'git push origin main'),
    CardEntry('pull', 'Pull', 'بُل', 'جلب التحديثات', 'git pull origin main'),
  ]),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Set<String> known = {};
  Map<String, ReviewState> reviews = {};
  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final raw = prefs.getString('review_states');
    Object? decoded;
    try {
      decoded = raw == null ? null : jsonDecode(raw);
    } on FormatException {
      decoded = null;
    }
    final restored = <String, ReviewState>{};
    if (decoded is Map) {
      for (final entry in decoded.entries) {
        final state = ReviewState.fromJson(entry.value);
        if (state != null) restored[entry.key.toString()] = state;
      }
    }
    setState(() {
      known = prefs.getStringList('known_cards')?.toSet() ?? {};
      reviews = restored;
    });
  }

  Future<void> _recordKnown(String id, ReviewRating rating) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      reviews[id] = scheduleReview(
        now: DateTime.now(),
        rating: rating,
        previous: reviews[id],
      );
      if (rating == ReviewRating.again) {
        known.remove(id);
      } else {
        known.add(id);
      }
    });
    await prefs.setStringList('known_cards', known.toList());
    await prefs.setString('review_states', jsonEncode(
      reviews.map((key, value) => MapEntry(key, value.toJson())),
    ));
  }

  Future<void> _openSearch() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const WordSearchPage()),
    );
  }

  Future<void> _openQuiz() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const QuizPage()),
    );
  }

  Future<void> _openReview() async {
    final now = DateTime.now();
    final dueCards = [
      for (final lesson in lessons)
        for (final card in lesson.cards)
          if (reviews[card.id]?.isDue(now) ?? false) card,
    ];
    if (dueCards.isEmpty) return;
    await _openLesson(Lesson('مراجعة البطاقات المستحقة', dueCards));
  }

  Future<void> _openLesson(Lesson lesson) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LessonPage(lesson: lesson, onKnown: _recordKnown),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final total = lessons.fold<int>(0, (sum, lesson) => sum + lesson.cards.length);
    final allIds = {for (final lesson in lessons) for (final card in lesson.cards) card.id};
    final due = reviews.entries.where((r) => allIds.contains(r.key) && r.value.isDue(DateTime.now())).length;
    const navy = Color(0xFF101D32);
    const purple = Color(0xFF6857CE);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: selectedTab == 0
              ? CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [navy, Color(0xFF28385C)],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(36),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Color(0x33FFFFFF),
                                  child: Icon(Icons.menu_book_rounded, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text('قاموسي', style: TextStyle(
                                    color: Colors.white, fontSize: 23,
                                    fontWeight: FontWeight.w800,
                                  )),
                                ),
                                IconButton(
                                  tooltip: 'الإنجازات',
                                  onPressed: () => setState(() => selectedTab = 2),
                                  icon: const Icon(Icons.insights_rounded, color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 36),
                            const Text('كل كلمة تقرّبك من هدفك',
                              style: TextStyle(color: Colors.white, fontSize: 26,
                                fontWeight: FontWeight.w800)),
                            const SizedBox(height: 9),
                            const Text('تعلّم اليوم، وتذكّر دائمًا',
                              style: TextStyle(color: Color(0xFFDDE9F4), fontSize: 15)),
                            const SizedBox(height: 28),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.13),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.23)),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 30),
                                  const SizedBox(width: 14),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('تقدمك في الإنجليزية التقنية',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 6),
                                      Text('${known.length} من $total بطاقة',
                                        style: const TextStyle(color: Color(0xFFDDE9F4))),
                                    ],
                                  )),
                                  CircularProgressIndicator(
                                    value: total == 0 ? 0 : known.length / total,
                                    backgroundColor: Colors.white24,
                                    color: const Color(0xFFFFB184),
                                    strokeWidth: 5,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 26, 20, 120),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Row(children: [
                            const Expanded(child: Text('الإنجليزية التقنية',
                              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: navy))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(color: const Color(0xFFE9E4FF),
                                borderRadius: BorderRadius.circular(24)),
                              child: const Text('القسم الأول', style: TextStyle(color: purple)),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          const Text('اختر درسًا وابدأ رحلة التعلم',
                            style: TextStyle(color: Color(0xFF667085))),
                          const SizedBox(height: 18),
                          Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              key: const Key('open_word_search'),
                              borderRadius: BorderRadius.circular(20),
                              onTap: _openSearch,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                                child: Row(children: [
                                  Icon(Icons.search_rounded, color: Color(0xFF6554C0), size: 27),
                                  SizedBox(width: 12),
                                  Expanded(child: Text('ابحث عن كلمة أو معناها',
                                    style: TextStyle(color: Color(0xFF667085), fontSize: 16))),
                                  Icon(Icons.arrow_back_ios_new_rounded,
                                    color: Color(0xFF667085), size: 16),
                                ]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Material(
                            color: const Color(0xFF101D32),
                            borderRadius: BorderRadius.circular(22),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: _openQuiz,
                              child: const Padding(
                                padding: EdgeInsets.all(20),
                                child: Row(children: [
                                  Icon(Icons.quiz_rounded, color: Color(0xFFFFB184), size: 32),
                                  SizedBox(width: 15),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('اختبر معلوماتك', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                                      SizedBox(height: 5),
                                      Text('اختبار سريع من 5 أسئلة', style: TextStyle(color: Color(0xFFDDE9F4))),
                                    ],
                                  )),
                                  Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                                ]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          for (var i = 0; i < lessons.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: () => _openLesson(lessons[i]),
                                  child: Padding(
                                    padding: const EdgeInsets.all(17),
                                    child: Row(children: [
                                      Container(
                                        width: 64, height: 68,
                                        decoration: BoxDecoration(
                                          color: [
                                            const Color(0xFFEAE5FF),
                                            const Color(0xFFFFE7DC),
                                            const Color(0xFFDDEEF3),
                                          ][i % 3],
                                          borderRadius: BorderRadius.circular(19),
                                        ),
                                        child: Icon([
                                          Icons.code_rounded,
                                          Icons.bug_report_rounded,
                                          Icons.account_tree_rounded,
                                        ][i % 3], size: 31, color: navy),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(lessons[i].title,
                                            style: const TextStyle(fontSize: 17,
                                              fontWeight: FontWeight.w800, color: navy)),
                                          const SizedBox(height: 7),
                                          Text('${lessons[i].cards.where((c) => known.contains(c.id)).length} / ${lessons[i].cards.length} بطاقات',
                                            style: const TextStyle(color: Color(0xFF667085))),
                                        ],
                                      )),
                                      const Icon(Icons.arrow_back_ios_new_rounded, size: 17, color: purple),
                                    ]),
                                  ),
                                ),
                              ),
                            ),
                        ]),
                      ),
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(22, 32, 22, 120),
                  children: [
                    Text(selectedTab == 1 ? 'المراجعة' : 'إنجازاتي',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: navy)),
                    const SizedBox(height: 14),
                    Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(selectedTab == 1 ? 'بطاقات مستحقة: $due' : 'أتقنت ${known.length} من $total بطاقة',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Text(selectedTab == 1
                              ? due == 0 ? 'لا توجد بطاقات مستحقة الآن. تعلّم كلمات جديدة أو عُد لاحقًا.' : 'لديك $due بطاقة جاهزة للمراجعة. استرجع معانيها لتثبيت ما تعلمته.'
                              : 'استمر في دراسة الدروس لترتفع نسبة تقدمك.'),
                          if (selectedTab == 1) ...[
                            const SizedBox(height: 18),
                            FilledButton(
                              onPressed: due > 0 ? _openReview : () => setState(() => selectedTab = 0),
                              child: Text(due > 0 ? 'ابدأ المراجعة الآن' : 'استعرض الدروس'),
                            ),
                          ],
                        ]),
                      ),
                    ),
                  ],
                ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
                  boxShadow: const [BoxShadow(
                    color: Color(0x220B1A33), blurRadius: 25, offset: Offset(0, 8),
                  )],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: selectedTab == i,
                          label: ['الرئيسية', 'المراجعة', 'إنجازاتي'][i],
                          child: InkWell(
                            onTap: () => setState(() => selectedTab = i),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon([
                                  Icons.home_rounded,
                                  Icons.refresh_rounded,
                                  Icons.bar_chart_rounded,
                                ][i], color: selectedTab == i ? const Color(0xFFFF653B) : navy,
                                  size: 27),
                                const SizedBox(height: 3),
                                Text(['الرئيسية', 'المراجعة', 'إنجازاتي'][i],
                                  style: TextStyle(fontSize: 11,
                                    fontWeight: selectedTab == i ? FontWeight.w800 : FontWeight.w500,
                                    color: selectedTab == i ? const Color(0xFFFF653B) : navy)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LessonPage extends StatefulWidget {
  final Lesson lesson;
  final Future<void> Function(String, ReviewRating) onKnown;

  const LessonPage({super.key, required this.lesson, required this.onKnown});

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  int index = 0;
  bool flipped = false;
  bool saving = false;

  void next() {
    if (index < widget.lesson.cards.length - 1) {
      setState(() {
        index++;
        flipped = false;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> rate(ReviewRating rating) async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await widget.onKnown(widget.lesson.cards[index].id, rating);
      if (mounted) next();
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.lesson.cards[index];
    const navy = Color(0xFF101D32);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F5F1),
          title: Text(widget.lesson.title, style: const TextStyle(fontWeight: FontWeight.w800)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Text('البطاقة ${index + 1} من ${widget.lesson.cards.length}',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: navy)),
                  const Spacer(),
                  Text('${((index + 1) * 100 / widget.lesson.cards.length).round()}%',
                    style: const TextStyle(color: Color(0xFF667085))),
                ]),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (index + 1) / widget.lesson.cards.length,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFFFF653B),
                  backgroundColor: const Color(0xFFE4E5EB),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    elevation: 2,
                    shadowColor: const Color(0x150B1A33),
                    child: InkWell(
                      key: const Key('flip_card'),
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => setState(() => flipped = !flipped),
                      child: Padding(
                        padding: const EdgeInsets.all(26),
                        child: Column(
                          children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAE5FF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(flipped ? 'المعنى والمثال' : 'الكلمة الإنجليزية',
                                  style: const TextStyle(color: Color(0xFF6554C0),
                                    fontWeight: FontWeight.w700)),
                              ),
                              const Spacer(),
                              const Icon(Icons.touch_app_rounded, color: Color(0xFF8992A2)),
                            ]),
                            Expanded(child: Center(child: SingleChildScrollView(
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                Text(card.word,
                                  textDirection: TextDirection.ltr,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 36,
                                    fontWeight: FontWeight.w900, color: navy)),
                                const SizedBox(height: 22),
                                if (flipped) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEEE6),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Text(card.pronunciation,
                                      style: const TextStyle(fontSize: 21, color: Color(0xFFB94824))),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(card.translation, textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 27,
                                      fontWeight: FontWeight.w800, color: navy)),
                                  const SizedBox(height: 28),
                                  const Text('مثال عملي',
                                    style: TextStyle(color: Color(0xFF667085),
                                      fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 9),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(17),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F5F9),
                                      borderRadius: BorderRadius.circular(17),
                                    ),
                                    child: SelectableText(card.example,
                                      textDirection: TextDirection.ltr,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 15, color: navy)),
                                  ),
                                ] else
                                  const Text('اضغط على البطاقة لمعرفة المعنى',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16, color: Color(0xFF667085))),
                              ]),
                            ))),
                            Text(flipped ? 'اضغط لإخفاء المعنى' : 'المس البطاقة لقلبها',
                              style: const TextStyle(color: Color(0xFF8992A2))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: OutlinedButton.icon(
                    onPressed: saving ? null : () => rate(ReviewRating.again),
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('أحتاج مراجعة'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: navy,
                    ),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton.icon(
                    onPressed: saving ? null : () => rate(ReviewRating.good),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('عرفتها'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFFFF653B),
                    ),
                  )),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  static final List<CardEntry> _cards = [
    for (final lesson in lessons) ...lesson.cards,
  ];
  int index = 0;
  int correct = 0;
  int? selected;

  List<String> get options {
    final answer = _cards[index].translation;
    final distractors = _cards.where((c) => c.id != _cards[index].id)
        .map((c) => c.translation).where((value) => value != answer).toList();
    final choices = <String>[answer];
    for (var offset = 0; offset < distractors.length && choices.length < 4; offset++) {
      final candidate = distractors[(index * 3 + offset) % distractors.length];
      if (!choices.contains(candidate)) choices.add(candidate);
    }
    choices.shuffleWithSeed(index + 42);
    return choices;
  }

  void answer(int choice) {
    if (selected != null) return;
    setState(() {
      selected = choice;
      if (options[choice] == _cards[index].translation) correct++;
    });
  }

  void next() {
    if (index == 4) {
      setState(() => index++);
    } else {
      setState(() {
        index++;
        selected = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final finished = index >= 5;
    final choices = finished ? <String>[] : options;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('اختبار الكلمات')),
        body: SafeArea(child: Padding(
          padding: const EdgeInsets.all(22),
          child: finished
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.emoji_events_rounded, size: 76, color: Color(0xFFFF653B)),
                  const SizedBox(height: 18),
                  const Text('أحسنت! انتهى الاختبار', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Text('نتيجتك: $correct من 5', style: const TextStyle(fontSize: 21)),
                  const SizedBox(height: 26),
                  FilledButton(onPressed: () => Navigator.pop(context), child: const Text('العودة للرئيسية')),
                ]))
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('السؤال ${index + 1} من 5', style: const TextStyle(fontSize: 16, color: Color(0xFF667085))),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: (index + 1) / 5, minHeight: 7, borderRadius: BorderRadius.circular(12)),
                  const SizedBox(height: 42),
                  const Text('ما معنى الكلمة التالية؟', style: TextStyle(fontSize: 19)),
                  const SizedBox(height: 16),
                  Text(_cards[index].word, textDirection: TextDirection.ltr, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: Color(0xFF101D32))),
                  const SizedBox(height: 36),
                  for (var i = 0; i < choices.length; i++) ...[
                    OutlinedButton(
                      onPressed: selected == null ? () => answer(i) : null,
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(18),
                        backgroundColor: selected != null && choices[i] == _cards[index].translation
                            ? const Color(0xFFE2F5E8)
                            : selected == i ? const Color(0xFFFFE4DE) : Colors.white),
                      child: Text(choices[i], style: const TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (selected != null) ...[
                    const Spacer(),
                    FilledButton(onPressed: next, child: Text(index == 4 ? 'عرض النتيجة' : 'السؤال التالي')),
                  ],
                ]),
        )),
      ),
    );
  }
}

extension _SeededShuffle<T> on List<T> {
  void shuffleWithSeed(int seed) {
    for (var i = length - 1; i > 0; i--) {
      final j = seed % (i + 1);
      final item = this[i];
      this[i] = this[j];
      this[j] = item;
      seed = (seed * 1664525 + 1013904223) & 0x7fffffff;
    }
  }
}


class WordSearchPage extends StatefulWidget {
  const WordSearchPage({super.key});

  @override
  State<WordSearchPage> createState() => _WordSearchPageState();
}

class _WordSearchPageState extends State<WordSearchPage> {
  final TextEditingController controller = TextEditingController();
  static final List<CardEntry> allCards = [
    for (final lesson in lessons) ...lesson.cards,
  ];
  String query = '';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final term = query.trim().toLowerCase();
    final results = term.isEmpty
        ? allCards
        : allCards.where((card) =>
            card.word.toLowerCase().contains(term) ||
            card.translation.toLowerCase().contains(term) ||
            card.pronunciation.toLowerCase().contains(term) ||
            card.example.toLowerCase().contains(term)).toList();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('البحث في قاموسي')),
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: TextField(
                key: const Key('word_search_field'),
                controller: controller,
                autofocus: false,
                onChanged: (value) => setState(() => query = value),
                decoration: InputDecoration(
                  hintText: 'اكتب كلمة إنجليزية أو معناها بالعربية',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: query.isEmpty ? null : IconButton(
                    tooltip: 'مسح البحث',
                    onPressed: () {
                      controller.clear();
                      setState(() => query = '');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('${results.length} كلمة',
                  style: const TextStyle(color: Color(0xFF667085))),
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? const Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 56, color: Color(0xFF98A2B3)),
                        SizedBox(height: 14),
                        Text('لم نعثر على كلمات مطابقة'),
                        SizedBox(height: 6),
                        Text('جرّب كلمة أخرى أو جزءًا منها',
                          style: TextStyle(color: Color(0xFF667085))),
                      ],
                    ))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final card = results[index];
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          child: ExpansionTile(
                            shape: const Border(),
                            collapsedShape: const Border(),
                            title: Text(card.word,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(fontSize: 19,
                                fontWeight: FontWeight.w800)),
                            subtitle: Text(card.translation),
                            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text('النطق: ${card.pronunciation}',
                                  style: const TextStyle(color: Color(0xFF6554C0))),
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: SelectableText(card.example,
                                  textDirection: TextDirection.ltr),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}
