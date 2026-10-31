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
    final decoded = raw == null ? null : jsonDecode(raw);
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
    final due = reviews.values.where((r) => r.isDue(DateTime.now())).length;
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
                              ? 'ابدأ درسًا للمراجعة والتعلّم. ستتوفر جلسة مخصصة للبطاقات المستحقة قريبًا.'
                              : 'استمر في دراسة الدروس لترتفع نسبة تقدمك.'),
                          if (selectedTab == 1) ...[
                            const SizedBox(height: 18),
                            FilledButton(
                              onPressed: () => setState(() => selectedTab = 0),
                              child: const Text('استعرض الدروس'),
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

  @override
  Widget build(BuildContext context) {
    final card = widget.lesson.cards[index];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.lesson.title)),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('البطاقة ${index + 1} من ${widget.lesson.cards.length}'),
              const SizedBox(height: 20),
              Expanded(
                child: InkWell(
                  key: const Key('flip_card'),
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => setState(() => flipped = !flipped),
                  child: Card(
                    child: SizedBox.expand(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(card.word, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 24),
                            if (flipped) ...[
                              Text(card.pronunciation, style: const TextStyle(fontSize: 20)),
                              const SizedBox(height: 12),
                              Text(card.translation, style: const TextStyle(fontSize: 26)),
                              const SizedBox(height: 24),
                              Text(card.example, textDirection: TextDirection.ltr, textAlign: TextAlign.center),
                            ] else
                              const Text('اضغط على البطاقة لمعرفة المعنى'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await widget.onKnown(card.id, ReviewRating.again);
                        if (mounted) next();
                      },
                      child: const Text('أحتاج مراجعة'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        await widget.onKnown(card.id, ReviewRating.good);
                        if (mounted) next();
                      },
                      child: const Text('عرفتها'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
