import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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

  @override
  Widget build(BuildContext context) {
    final total = lessons.fold<int>(0, (value, lesson) => value + lesson.cards.length);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('قاموسي')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('الإنجليزية التقنية', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('أتقنت ${known.length} من $total بطاقة'),
            Text('مستحقة للمراجعة الآن: ${reviews.values.where((review) => review.isDue(DateTime.now())).length}'),
            const SizedBox(height: 24),
            for (final lesson in lessons)
              Card(
                child: ListTile(
                  title: Text(lesson.title),
                  subtitle: Text('${lesson.cards.where((card) => known.contains(card.id)).length} / ${lesson.cards.length}'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => LessonPage(lesson: lesson, onKnown: _recordKnown),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                ),
              ),
          ],
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
