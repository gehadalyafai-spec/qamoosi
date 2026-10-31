import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'core/review_scheduler.dart';
import 'core/smart_study_plan.dart';
import 'core/quiz_stats.dart';
import 'core/daily_learning_progress.dart';
import 'core/favorite_words_repository.dart';
import 'data/word_insights.dart';
import 'data/vocabulary_expansion.dart';
import 'features/learning/word_insight_details.dart';
import 'features/quiz/quiz_mistakes_review.dart';
import 'features/daily/daily_learning_widgets.dart';
import 'features/achievements/achievements_panel.dart';
import 'features/achievements/learning_overview.dart';
import 'features/path/learning_path_card.dart';
import 'features/plan/smart_study_plan_page.dart';
import 'features/practice/practice_page.dart';
import 'features/practice/practice_mistakes.dart';
import 'features/practice/practice_stats.dart';

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

enum LearningLevel { beginner, intermediate }

extension LearningLevelLabel on LearningLevel {
  String get label => switch (this) {
    LearningLevel.beginner => 'مبتدئ',
    LearningLevel.intermediate => 'متوسط',
  };
}

class Lesson {
  final String title;
  final List<CardEntry> cards;
  final LearningLevel level;
  const Lesson(this.title, this.cards, {this.level = LearningLevel.beginner});
}

/// A null level means all lessons, including any levels added in the future.
List<Lesson> filterLessonsByLevel(
  Iterable<Lesson> catalog,
  LearningLevel? level,
) => [
  for (final lesson in catalog)
    if (level == null || lesson.level == level) lesson,
];

/// Find lessons by topic, vocabulary spelling or Arabic meaning offline.
bool matchesLessonQuery(Lesson lesson, String query) {
  final term = query.trim().toLowerCase();
  if (term.isEmpty) return true;
  return lesson.title.toLowerCase().contains(term) ||
      lesson.cards.any((card) =>
          card.word.toLowerCase().contains(term) ||
          card.translation.toLowerCase().contains(term));
}


final lessons = <Lesson>[
  Lesson('أساسيات البرمجة', [
    CardEntry('variable', 'Variable', 'ڤيريَبُل', 'متغير', 'int count = 1;'),
    CardEntry('constant', 'Constant', 'كونستَنت', 'ثابت', 'const appName = "قاموسي";'),
    CardEntry('function', 'Function', 'فانكشن', 'دالة', 'int add(int a, int b) => a + b;'),
    CardEntry('parameter', 'Parameter', 'باراميتر', 'معامل الدالة', 'void greet(String name) {}'),
    CardEntry('return', 'Return', 'ريتيرن', 'إرجاع قيمة', 'return total;'),
    CardEntry("string", "String", "سترينغ", "سلسلة نصية", "String name = 'Qamoosi';"),
    CardEntry("integer", "Integer", "إنتِجَر", "عدد صحيح", "int cards = 30;"),
    CardEntry("boolean", "Boolean", "بوليَن", "قيمة منطقية", "bool isComplete = false;"),
    CardEntry("list", "List", "لِست", "قائمة", "final words = ['File', 'Folder'];"),
    CardEntry("object", "Object", "أوبجِكت", "كائن", "final date = DateTime.now();"),
  ]),
  Lesson('الأخطاء والتطوير', [
    CardEntry('bug', 'Bug', 'بَغ', 'خلل برمجي', 'Fix the bug.'),
    CardEntry('debug', 'Debug', 'ديبَغ', 'تصحيح الأخطاء', 'flutter run --debug'),
    CardEntry('syntax', 'Syntax', 'سينتاكس', 'قواعد الصياغة البرمجية', 'Syntax error'),
    CardEntry('build', 'Build', 'بيلد', 'بناء التطبيق', 'flutter build apk'),
    CardEntry('release', 'Release', 'ريليس', 'إصدار للتوزيع', 'flutter build apk --release'),
    CardEntry("error", "Error", "إيرَر", "خطأ", "Error: file not found."),
    CardEntry("exception", "Exception", "إكسبشن", "استثناء", "throw Exception('Invalid input');"),
    CardEntry("test", "Test", "تِست", "اختبار", "flutter test"),
    CardEntry("fix", "Fix", "فِكس", "إصلاح", "Fix the broken search."),
    CardEntry("deploy", "Deploy", "دِبلوي", "نشر التطبيق", "Deploy the app to the server."),
  ], level: LearningLevel.intermediate),
  Lesson('Git وGitHub', [
    CardEntry('repository', 'Repository', 'ريبوزيتوري', 'مستودع المشروع', 'git clone URL'),
    CardEntry('branch', 'Branch', 'برانش', 'فرع المشروع', 'git branch development'),
    CardEntry('commit', 'Commit', 'كومِت', 'تسجيل تغييرات', 'git commit -m "update"'),
    CardEntry('push', 'Push', 'بُش', 'رفع التغييرات', 'git push origin main'),
    CardEntry('pull', 'Pull', 'بُل', 'جلب التحديثات', 'git pull origin main'),
    CardEntry("git", "Git", "جِت", "نظام إدارة الإصدارات", "git --version"),
    CardEntry("github", "GitHub", "جِت هَب", "منصة استضافة المستودعات", "Open a pull request on GitHub."),
    CardEntry("merge", "Merge", "ميرج", "دمج الفروع", "git merge development"),
    CardEntry("clone", "Clone", "كلون", "استنساخ المستودع", "git clone REPO_URL"),
    CardEntry("status", "Status", "ستاتَس", "حالة الملفات", "git status"),
  ], level: LearningLevel.intermediate),

  Lesson('الملفات والمجلدات', [
    CardEntry('file', 'File', 'فايل', 'ملف', 'Open the file.'),
    CardEntry('folder', 'Folder', 'فولدر', 'مجلد', 'Create a new folder.'),
    CardEntry('path', 'Path', 'باث', 'مسار الملف', 'lib/main.dart'),
    CardEntry('save', 'Save', 'سيف', 'حفظ', 'Save your changes.'),
    CardEntry('open', 'Open', 'أوبِن', 'فتح', 'Open the project.'),
    CardEntry("directory", "Directory", "دايركتوري", "دليل أو مجلد", "Directory: lib/features/"),
    CardEntry("extension", "Extension", "إكستنشن", "امتداد الملف", "main.dart"),
    CardEntry("rename", "Rename", "ري نيم", "إعادة تسمية", "Rename notes.txt to summary.txt."),
    CardEntry("delete", "Delete", "دِليت", "حذف", "Delete an unused file."),
    CardEntry("copy", "Copy", "كوبي", "نسخ", "Copy the file to a backup folder."),
  ]),
  Lesson('الويب وقواعد البيانات', [
    CardEntry('server', 'Server', 'سيرفر', 'خادم', 'The server is running.'),
    CardEntry('client', 'Client', 'كلاينت', 'عميل', 'The client sends a request.'),
    CardEntry('database', 'Database', 'داتابيس', 'قاعدة بيانات', 'Store data in the database.'),
    CardEntry('api', 'API', 'إيه بي آي', 'واجهة برمجة التطبيقات', 'Call the API endpoint.'),
    CardEntry('request', 'Request', 'ريكويست', 'طلب', 'Send a request to the server.'),
    CardEntry("network", "Network", "نِتوورك", "شبكة", "Check the network connection."),
    CardEntry("http", "HTTP", "إتش تي تي بي", "بروتوكول الويب", "GET /api/products HTTP/1.1"),
    CardEntry("endpoint", "Endpoint", "إندبوينت", "نقطة اتصال برمجية", "GET /api/orders"),
    CardEntry("response", "Response", "رِسبونس", "استجابة", "HTTP 200 OK"),
    CardEntry("json", "JSON", "جَيْسُن", "صيغة تبادل بيانات", "{\"ok\": true}"),
  ], level: LearningLevel.intermediate),
  Lesson('تشغيل البرامج', [
    CardEntry('run', 'Run', 'رَن', 'تشغيل', 'flutter run'),
    CardEntry('compile', 'Compile', 'كومبايل', 'ترجمة الكود إلى صيغة قابلة للتنفيذ', 'Compile the application.'),
    CardEntry('output', 'Output', 'آوتبُت', 'مخرجات', 'Print the output.'),
    CardEntry('input', 'Input', 'إنبُت', 'مدخلات', 'Enter your input.'),
    CardEntry('result', 'Result', 'ريزَلت', 'نتيجة', 'Show the result.'),
    CardEntry("print", "Print", "برِنت", "طباعة المخرجات", "print('Hello');"),
    CardEntry("command", "Command", "كوماند", "أمر", "flutter doctor"),
    CardEntry("terminal", "Terminal", "تيرمِنَل", "الطرفية", "Open the terminal in VS Code."),
    CardEntry("program", "Program", "بروغرام", "برنامج", "void main() { print('Hi'); }"),
    CardEntry("process", "Process", "بروسِس", "عملية قيد التشغيل", "The build process finished."),
  ]),
  // Additional lessons are appended rather than modifying the original sixty
  // cards, so previously saved mastery, favorites and review dates survive.
  for (final extra in expandedVocabulary)
    Lesson(
      extra.title,
      [
        for (final card in extra.cards)
          CardEntry(
            card.id,
            card.word,
            card.pronunciation,
            card.translation,
            card.example,
          ),
      ],
      level: extra.intermediate
          ? LearningLevel.intermediate
          : LearningLevel.beginner,
    ),
];

/// Matches a vocabulary card across its spelling, translation and teaching notes.
bool matchesVocabularyQuery(CardEntry card, String query) {
  final term = query.trim().toLowerCase();
  if (term.isEmpty) {
    return true;
  }
  final insight = wordInsightFor(card.id);
  return [
    card.word,
    card.translation,
    card.pronunciation,
    card.example,
    if (insight != null) ...[
      insight.explanation,
      insight.projectUse,
      insight.practiceQuestion,
    ],
  ].any((text) => text.toLowerCase().contains(term));
}

double lessonProgress(Lesson lesson, Set<String> knownCards) {
  if (lesson.cards.isEmpty) {
    return 0;
  }
  final completed = lesson.cards.where(
    (card) => knownCards.contains(card.id),
  ).length;
  return completed / lesson.cards.length;
}

/// Work through the beginner lessons first, then intermediate lessons.
/// The original order within each level remains unchanged.
Lesson? recommendNextLesson(
  Iterable<Lesson> catalog,
  Set<String> knownCards,
) {
  for (final level in LearningLevel.values) {
    for (final lesson in catalog) {
      if (lesson.level == level &&
          lesson.cards.isNotEmpty &&
          lesson.cards.any((card) => !knownCards.contains(card.id))) {
        return lesson;
      }
    }
  }
  return null;
}

/// Resume at the first not-yet-mastered card, without changing its original ID.
Lesson lessonRemainingToLearn(Lesson lesson, Set<String> knownCards) {
  return Lesson(
    lesson.title,
    [
      for (final card in lesson.cards)
        if (!knownCards.contains(card.id)) card,
    ],
    level: lesson.level,
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  Set<String> known = {};
  Map<String, ReviewState> reviews = {};
  QuizStats quizStats = const QuizStats();
  PracticeStats practiceStats = const PracticeStats();
  DailyLearningProgress dailyProgress = DailyLearningProgress();
  int pendingPracticeMistakes = 0;
  LearningLevel? selectedLevel;
  String lessonQuery = '';
  final TextEditingController _lessonSearchController =
      TextEditingController();
  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lessonSearchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
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
      quizStats = QuizStats.fromPreferences(prefs);
      practiceStats = PracticeStats.fromPreferences(prefs);
      pendingPracticeMistakes =
          PracticeMistakes.fromPreferences(prefs).pendingCount;
      final dailyJson = prefs.getString(DailyLearningProgress.storageKey);
      Object? decodedDaily;
      try {
        decodedDaily = dailyJson == null ? null : jsonDecode(dailyJson);
      } on FormatException {
        decodedDaily = null;
      }
      dailyProgress = DailyLearningProgress.fromJson(decodedDaily);
    });
  }

  Future<void> _recordKnown(String id, ReviewRating rating) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    setState(() {
      reviews[id] = scheduleReview(
        now: now,
        rating: rating,
        previous: reviews[id],
      );
      if (rating == ReviewRating.again) {
        known.remove(id);
      } else {
        known.add(id);
        dailyProgress = dailyProgress.recordSuccess(id, now);
      }
    });
    await prefs.setStringList('known_cards', known.toList());
    await prefs.setString('review_states', jsonEncode(
      reviews.map((key, value) => MapEntry(key, value.toJson())),
    ));
    await prefs.setString(
      DailyLearningProgress.storageKey,
      jsonEncode(dailyProgress.toJson()),
    );
  }

  Future<void> _changeDailyGoal(int goal) async {
    if (!DailyLearningProgress.allowedGoals.contains(goal)) {
      return;
    }
    setState(() {
      dailyProgress = dailyProgress.withGoal(goal);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      DailyLearningProgress.storageKey,
      jsonEncode(dailyProgress.toJson()),
    );
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
    if (mounted) await _load();
  }

  Future<void> _openPractice() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const PracticePage()),
    );
    if (mounted) {
      await _load();
    }
  }

  Future<void> _openMistakeReview() async {
    if (pendingPracticeMistakes == 0) {
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => const PracticePage(reviewMistakes: true),
      ),
    );
    if (mounted) {
      await _load();
    }
  }

  SmartStudyPlan _currentSmartStudyPlan() => SmartStudyPlan.build(
    lessons: [
      for (final lesson in lessons)
        StudyPlanLesson(
          title: lesson.title,
          levelRank: lesson.level.index,
          cards: [
            for (final card in lesson.cards)
              StudyPlanCard(id: card.id, word: card.word),
          ],
        ),
    ],
    knownIds: known,
    reviews: reviews,
    dailyProgress: dailyProgress,
    now: DateTime.now(),
    pendingPracticeMistakes: pendingPracticeMistakes,
  );

  Future<SmartStudyPlan> _loadSmartStudyPlan() async {
    await _load();
    return _currentSmartStudyPlan();
  }

  Future<void> _openPlanCards(
    List<String> cardIds, {
    required String title,
  }) async {
    if (cardIds.isEmpty) return;
    final catalog = {
      for (final lesson in lessons)
        for (final card in lesson.cards) card.id: card,
    };
    final cards = [
      for (final id in cardIds)
        if (catalog.containsKey(id)) catalog[id]!,
    ];
    if (cards.isEmpty) return;
    await _openLesson(Lesson(title, cards));
  }

  Future<void> _openSmartStudyPlan() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SmartStudyPlanPage(
          loadPlan: _loadSmartStudyPlan,
          onReviewCards: (ids) => _openPlanCards(
            ids, title: 'مراجعات خطتي اليوم',
          ),
          onLearnCards: (ids) => _openPlanCards(
            ids, title: 'كلمات جديدة لليوم',
          ),
          onReviewMistakes: _openMistakeReview,
          onPractice: _openPractice,
        ),
      ),
    );
    if (mounted) await _load();
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
    final recommendedLesson = recommendNextLesson(lessons, known);
    final smartPlan = _currentSmartStudyPlan();
    final shownLessonIndices = [
      for (var i = 0; i < lessons.length; i++)
        if ((selectedLevel == null || lessons[i].level == selectedLevel) &&
            matchesLessonQuery(lessons[i], lessonQuery))
          i,
    ];
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
                          DailyGoalCard(
                            progress: dailyProgress,
                            now: DateTime.now(),
                            onGoalChanged: _changeDailyGoal,
                          ),
                          const SizedBox(height: 16),
                          Material(
                             color: const Color(0xFFECE7FF),
                             borderRadius: BorderRadius.circular(24),
                             child: InkWell(
                               key: const Key('open_smart_study_plan'),
                               borderRadius: BorderRadius.circular(24),
                               onTap: _openSmartStudyPlan,
                               child: Padding(
                                 padding: const EdgeInsets.all(19),
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     const Row(children: [
                                       Icon(Icons.auto_awesome_rounded,
                                         color: Color(0xFF6857CE), size: 28),
                                       SizedBox(width: 11),
                                       Expanded(child: Text('خطتي الذكية اليوم',
                                         style: TextStyle(
                                           color: Color(0xFF101D32),
                                           fontSize: 19,
                                           fontWeight: FontWeight.w900))),
                                       Icon(Icons.arrow_back_ios_new_rounded,
                                         color: Color(0xFF6857CE), size: 16),
                                     ]),
                                     const SizedBox(height: 9),
                                     Text(
                                       smartPlan.goalMet
                                           ? 'وصلت إلى هدفك اليوم؛ واصل تثبيت ما تعلمته.'
                                           : 'المتبقي لهدفك: ${smartPlan.remainingToday} بطاقات.',
                                       style: const TextStyle(
                                         color: Color(0xFF51607A), fontSize: 14),
                                     ),
                                     const SizedBox(height: 12),
                                     Wrap(
                                       spacing: 8,
                                       runSpacing: 7,
                                       children: [
                                         _HomePlanChip(
                                           text: 'مراجعات: ${smartPlan.dueCount}',
                                         ),
                                         _HomePlanChip(
                                           text: 'كلمات جديدة: ${smartPlan.newCards.length}',
                                         ),
                                         _HomePlanChip(
                                           text: 'أخطاء: ${smartPlan.pendingPracticeMistakes}',
                                         ),
                                       ],
                                     ),
                                   ],
                                 ),
                               ),
                             ),
                           ),
                           const SizedBox(height: 16),
                           LearningPathCard(
                            lessonTitle: recommendedLesson?.title,
                            levelLabel: recommendedLesson?.level.label,
                            learned: recommendedLesson == null
                                ? 0
                                : recommendedLesson.cards.where(
                                    (card) => known.contains(card.id),
                                  ).length,
                            total: recommendedLesson?.cards.length ?? 0,
                            onStart: recommendedLesson == null
                                ? null
                                : () => _openLesson(
                                    lessonRemainingToLearn(recommendedLesson, known),
                                  ),
                          ),
                          const SizedBox(height: 16),
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
                              key: const Key('open_quiz'),
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
                                      Text('اختبار من 6 أسئلة متنوعة', style: TextStyle(color: Color(0xFFDDE9F4))),
                                    ],
                                  )),
                                  Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                                ]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Material(
                            color: const Color(0xFFE9F1FF),
                            borderRadius: BorderRadius.circular(22),
                            child: InkWell(
                              key: const Key('open_practice'),
                              borderRadius: BorderRadius.circular(22),
                              onTap: _openPractice,
                              child: const Padding(
                                padding: EdgeInsets.all(19),
                                child: Row(children: [
                                  Icon(Icons.psychology_rounded,
                                    color: Color(0xFF3565A8), size: 32),
                                  SizedBox(width: 15),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('طبّق ما تعلّمته',
                                        style: TextStyle(
                                          color: Color(0xFF101D32),
                                          fontSize: 18, fontWeight: FontWeight.w800)),
                                      SizedBox(height: 5),
                                      Text('6 مواقف تفاعلية مع شرح الإجابات',
                                        style: TextStyle(
                                          color: Color(0xFF51647D), fontSize: 13)),
                                    ],
                                  )),
                                  Icon(Icons.arrow_back_ios_new_rounded,
                                    color: Color(0xFF3565A8), size: 17),
                                ]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Material(
                            color: const Color(0xFFF4EBFF),
                            borderRadius: BorderRadius.circular(22),
                            child: InkWell(
                              key: const Key('open_mistake_review'),
                              borderRadius: BorderRadius.circular(22),
                              onTap: pendingPracticeMistakes > 0
                                  ? _openMistakeReview
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(19),
                                child: Row(children: [
                                  const Icon(Icons.rule_rounded,
                                    color: Color(0xFF6857CE), size: 32),
                                  const SizedBox(width: 15),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('مراجعة أخطائي',
                                        style: TextStyle(
                                          color: Color(0xFF101D32),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 5),
                                      Text(pendingPracticeMistakes > 0
                                          ? 'مواقف تحتاج مراجعة: $pendingPracticeMistakes'
                                          : 'لا توجد أخطاء معلّقة حاليًا',
                                        key: const Key('pending_mistakes_count'),
                                        style: const TextStyle(
                                          color: Color(0xFF65547F),
                                          fontSize: 13)),
                                    ],
                                  )),
                                  Icon(
                                    pendingPracticeMistakes > 0
                                        ? Icons.arrow_back_ios_new_rounded
                                        : Icons.check_circle_outline_rounded,
                                    color: const Color(0xFF6857CE),
                                    size: 19,
                                  ),
                                ]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text('اختر مستواك', style: TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w800, color: navy)),
                          const SizedBox(height: 7),
                          const Text('انتقل بين المستويات دون أن تفقد تقدمك المحفوظ',
                            style: TextStyle(color: Color(0xFF667085), fontSize: 13)),
                          const SizedBox(height: 14),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(children: [
                              ChoiceChip(
                                key: const Key('level_all'),
                                label: const Text('كل الدروس'),
                                selected: selectedLevel == null,
                                onSelected: (_) => setState(() => selectedLevel = null),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                key: const Key('level_beginner'),
                                label: const Text('المبتدئ'),
                                selected: selectedLevel == LearningLevel.beginner,
                                onSelected: (_) => setState(
                                  () => selectedLevel = LearningLevel.beginner),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                key: const Key('level_intermediate'),
                                label: const Text('المتوسط'),
                                selected: selectedLevel == LearningLevel.intermediate,
                                onSelected: (_) => setState(
                                  () => selectedLevel = LearningLevel.intermediate),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            key: const Key('lesson_search_field'),
                            controller: _lessonSearchController,
                            onChanged: (value) => setState(
                              () => lessonQuery = value,
                            ),
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'ابحث عن درس أو كلمة ضمن الدروس',
                              prefixIcon: const Icon(
                                Icons.manage_search_rounded,
                                color: Color(0xFF6857CE)),
                              suffixIcon: lessonQuery.isEmpty
                                  ? null
                                  : IconButton(
                                      key: const Key('clear_lesson_search'),
                                      tooltip: 'مسح بحث الدروس',
                                      onPressed: () {
                                        _lessonSearchController.clear();
                                        setState(() => lessonQuery = '');
                                      },
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'الدروس المعروضة: ${shownLessonIndices.length}',
                            key: const Key('level_lesson_count'),
                            style: const TextStyle(
                              fontSize: 13, color: Color(0xFF667085)),
                          ),
                          const SizedBox(height: 16),
                          if (shownLessonIndices.isEmpty)
                            const Padding(
                              key: Key('no_lesson_matches'),
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Column(
                                children: [
                                  Icon(Icons.search_off_rounded,
                                    size: 44, color: Color(0xFF98A2B3)),
                                  SizedBox(height: 9),
                                  Text('لا توجد دروس مطابقة للبحث',
                                    style: TextStyle(color: Color(0xFF667085))),
                                ],
                              ),
                            ),
                          for (final i in shownLessonIndices)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                child: InkWell(
                                  key: Key('lesson_$i'),
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
                                            const Color(0xFFE8F2E3),
                                            const Color(0xFFFFEEDA),
                                            const Color(0xFFE8EAFB),
                                          ][i % 6],
                                          borderRadius: BorderRadius.circular(19),
                                        ),
                                        child: Icon([
                                          Icons.code_rounded,
                                          Icons.bug_report_rounded,
                                          Icons.account_tree_rounded,
                                          Icons.folder_copy_rounded,
                                          Icons.cloud_rounded,
                                          Icons.play_circle_outline_rounded,
                                        ][i % 6], size: 31, color: navy),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(lessons[i].title,
                                            style: const TextStyle(fontSize: 17,
                                              fontWeight: FontWeight.w800, color: navy)),
                                          const SizedBox(height: 5),
                                          Text('المستوى: ${lessons[i].level.label}',
                                            style: const TextStyle(
                                              fontSize: 12, fontWeight: FontWeight.w700,
                                              color: Color(0xFF6857CE))),
                                          const SizedBox(height: 7),
                                          Text('${lessons[i].cards.where((c) => known.contains(c.id)).length} / ${lessons[i].cards.length} بطاقات',
                                            style: const TextStyle(color: Color(0xFF667085))),
                                          const SizedBox(height: 10),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: LinearProgressIndicator(
                                              value: lessonProgress(lessons[i], known),
                                              minHeight: 6,
                                              color: const Color(0xFFFF653B),
                                              backgroundColor: const Color(0xFFECEEF3),
                                            ),
                                          ),
                                          if (lessonProgress(lessons[i], known) == 1) ...[
                                            const SizedBox(height: 6),
                                            const Text('أكملت هذا الدرس ✓',
                                              style: TextStyle(color: Color(0xFF21865B),
                                                fontSize: 12, fontWeight: FontWeight.w700)),
                                          ],
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
              : selectedTab == 2
                  ? AchievementsPanel(
                      lessons: [
                        for (final lesson in lessons)
                          LessonAchievement(
                            title: lesson.title,
                            completed: lesson.cards.where((card) => known.contains(card.id)).length,
                            total: lesson.cards.length,
                          ),
                      ],
                      dueCards: due,
                      quizStats: quizStats,
                      dailyProgress: dailyProgress,
                      levelProgress: [
                        for (final level in LearningLevel.values)
                          LearningLevelProgress.fromCardIds(
                            label: level.label,
                            lessonCardIds: [
                              for (final lesson in lessons)
                                if (lesson.level == level)
                                  lesson.cards.map((card) => card.id),
                            ],
                            knownIds: known,
                          ),
                      ],
                      practiceStats: practiceStats,
                      pendingMistakes: pendingPracticeMistakes,
                      nextLessonTitle: recommendedLesson?.title,
                      onContinueLesson: recommendedLesson == null
                          ? null
                          : () => _openLesson(
                              lessonRemainingToLearn(recommendedLesson, known),
                            ),
                      onPractice: _openPractice,
                      onReviewMistakes: pendingPracticeMistakes > 0
                          ? _openMistakeReview
                          : null,
                      scheduledCards: reviews.entries.where((entry) =>
                        allIds.contains(entry.key) && !entry.value.isDue(DateTime.now())).length,
                      onExplore: () => setState(() => selectedTab = 0),
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

class _HomePlanChip extends StatelessWidget {
  const _HomePlanChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(text, style: const TextStyle(
      color: Color(0xFF514078),
      fontSize: 12,
      fontWeight: FontWeight.w700)),
  );
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
    final insight = wordInsightFor(card.id);
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
                                  if (insight != null) ...[
                                    const SizedBox(height: 18),
                                    WordInsightDetails(insight: insight),
                                  ],
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

/// Six questions per attempt, fairly rotated across *all* lessons.
///
/// With 30 lessons of ten words each, five successive attempts cover all
/// lessons once. After fifty attempts every one of the 300 cards has appeared
/// exactly once. Older quiz scores remain valid because each attempt still
/// contains six questions, even when additional lessons are introduced.
List<CardEntry> buildQuizCards(int completedAttempts) {
  const questionsPerQuiz = 6;
  final available = [
    for (final lesson in lessons)
      if (lesson.cards.isNotEmpty) lesson,
  ];
  if (available.isEmpty) return const [];
  final attempts = completedAttempts < 0 ? 0 : completedAttempts;
  final groups = (available.length + questionsPerQuiz - 1) ~/ questionsPerQuiz;
  final group = attempts % groups;
  final rotation = attempts ~/ groups;
  final start = group * questionsPerQuiz;
  return [
    for (var offset = 0;
        offset < questionsPerQuiz && start + offset < available.length;
        offset++)
      available[start + offset].cards[
        (rotation + offset) % available[start + offset].cards.length
      ],
  ];
}

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  static const Duration correctAnswerDelay = Duration(milliseconds: 700);
  Timer? _autoAdvanceTimer;
  final ScrollController _choicesScrollController = ScrollController(keepScrollOffset: false);
  final List<QuizMistake> _mistakes = [];

  static final List<CardEntry> _allCards = [
    for (final lesson in lessons) ...lesson.cards,
  ];

  List<CardEntry> _cards = [];
  QuizStats _stats = const QuizStats();
  int index = 0;
  int correct = 0;
  int? selected;
  bool _ready = false;
  bool _saving = false;
  bool _finished = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _choicesScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = null;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final stats = QuizStats.fromPreferences(prefs);
    setState(() {
      _stats = stats;
      _cards = buildQuizCards(stats.attempts);
      _mistakes.clear();
      index = 0;
      correct = 0;
      selected = null;
      _finished = false;
      _saving = false;
      _saveError = null;
      _ready = true;
    });
  }

  List<String> get options {
    final current = _cards[index];
    final others = _allCards
        .where((card) => card.id != current.id && card.translation != current.translation)
        .map((card) => card.translation)
        .toSet()
        .toList();
    final choices = <String>[current.translation];
    for (var offset = 0; choices.length < 4 && offset < others.length; offset++) {
      choices.add(others[(index * 5 + offset) % others.length]);
    }
    choices.shuffleWithSeed(index + 42 + _stats.attempts);
    return choices;
  }

  void answer(int choice) {
    if (selected != null || _saving || _finished) return;
    final choices = options;
    if (choice < 0 || choice >= choices.length) return;
    final isCorrect = choices[choice] == _cards[index].translation;
    final answeredIndex = index;
    setState(() {
      selected = choice;
      if (isCorrect) {
        correct++;
      } else {
        final card = _cards[index];
        final insight = wordInsightFor(card.id);
        _mistakes.add(QuizMistake(
          word: card.word,
          pronunciation: card.pronunciation,
          selectedTranslation: choices[choice],
          correctTranslation: card.translation,
          example: card.example,
          explanation: insight?.explanation ?? card.translation,
          projectUse: insight?.projectUse ?? '',
        ));
      }
    });

    if (!isCorrect) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _choicesScrollController.hasClients) {
          _choicesScrollController.animateTo(
            _choicesScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
          );
        }
      });
    }

    // Show the correct answer briefly, then continue without another tap.
    // A wrong answer stays on the screen until the learner continues.
    if (isCorrect) {
      _autoAdvanceTimer?.cancel();
      _autoAdvanceTimer = Timer(correctAnswerDelay, () {
        if (mounted && index == answeredIndex &&
            selected == choice && !_finished && !_saving) {
          next();
        }
      });
    }
  }

  Future<void> next() async {
    if (selected == null || _saving || _finished) return;
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = null;
    if (index + 1 < _cards.length) {
      setState(() {
        index++;
        selected = null;
        _saveError = null;
      });
      if (_choicesScrollController.hasClients) {
        _choicesScrollController.jumpTo(0);
      }
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final updated = await QuizStats.record(prefs, correct);
      if (!mounted) return;
      setState(() {
        _stats = updated;
        _finished = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _saveError = 'تعذّر حفظ النتيجة. حاول مجددًا.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reviewMistakes() async {
    if (_mistakes.isEmpty) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => QuizMistakesReviewPage(
          mistakes: List<QuizMistake>.unmodifiable(_mistakes),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF101D32);
    const orange = Color(0xFFFF653B);
    final choices = _ready && !_finished && _cards.isNotEmpty ? options : <String>[];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('اختبار الكلمات')),
        body: SafeArea(
          child: !_ready
              ? const Center(child: CircularProgressIndicator())
              : _finished
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.emoji_events_rounded, size: 76, color: orange),
                          const SizedBox(height: 18),
                          const Text('أحسنت! انتهى الاختبار',
                            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 12),
                          Text('نتيجتك: $correct من ${_cards.length}',
                            style: const TextStyle(fontSize: 21)),
                          const SizedBox(height: 10),
                          Text('أفضل نتيجة: ${_stats.bestScore} من ${_cards.length}',
                            style: const TextStyle(color: Color(0xFF667085))),
                          const SizedBox(height: 13),
                          if (_mistakes.isEmpty)
                            const Text(
                              'رائع! أجبت عن جميع الكلمات بشكل صحيح.',
                              key: Key('quiz_no_mistakes'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF21865B),
                                fontWeight: FontWeight.w800),
                            )
                          else ...[
                            Text(
                              _mistakes.length == 1
                                  ? 'هناك كلمة واحدة تحتاج مراجعة.'
                                  : 'هناك ${_mistakes.length} كلمات تحتاج مراجعة.',
                              key: const Key('quiz_mistake_summary'),
                              style: const TextStyle(
                                color: Color(0xFF667085)),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              key: const Key('quiz_review_mistakes'),
                              onPressed: _reviewMistakes,
                              icon: const Icon(Icons.school_outlined),
                              label: Text(_mistakes.length == 1
                                  ? 'راجع الكلمة'
                                  : 'راجع ${_mistakes.length} كلمات'),
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () {
                              setState(() => _ready = false);
                              _loadQuiz();
                            },
                            icon: const Icon(Icons.replay_rounded),
                            label: const Text('اختبار جديد'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('العودة للرئيسية'),
                          ),
                        ]),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text('السؤال ${index + 1} من ${_cards.length}',
                          style: const TextStyle(fontSize: 16, color: Color(0xFF667085))),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: (index + 1) / _cards.length,
                          minHeight: 7,
                          borderRadius: BorderRadius.circular(12),
                          color: orange,
                        ),
                        const SizedBox(height: 15),
                        Expanded(
                          child: ListView(
                            controller: _choicesScrollController,
                            children: [
                              const SizedBox(height: 18),
                              const Text('ما معنى الكلمة التالية؟',
                                style: TextStyle(fontSize: 19, color: navy)),
                              const SizedBox(height: 19),
                              Text(_cards[index].word,
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 36,
                                  fontWeight: FontWeight.w800, color: navy)),
                              const SizedBox(height: 29),
                              for (var i = 0; i < choices.length; i++) ...[
                                OutlinedButton(
                                  key: Key('quiz_choice_$i'),
                                  onPressed: selected == null ? () => answer(i) : null,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.all(18),
                                    backgroundColor: selected != null &&
                                            choices[i] == _cards[index].translation
                                        ? const Color(0xFFE2F5E8)
                                        : selected == i
                                            ? const Color(0xFFFFE4DE)
                                            : Colors.white,
                                  ),
                                  child: Text(choices[i],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 16)),
                                ),
                                const SizedBox(height: 10),
                              ],
                              if (selected != null &&
                                  choices[selected!] != _cards[index].translation) ...[
                                const SizedBox(height: 10),
                                Container(
                                  key: const Key('quiz_wrong_feedback'),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0EB),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('الإجابة الصحيحة',
                                        style: TextStyle(
                                          color: Color(0xFFB94824),
                                          fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 8),
                                      Text(_cards[index].translation,
                                        style: const TextStyle(
                                          color: navy,
                                          fontSize: 19,
                                          fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 5),
                                      Text('النطق: ${_cards[index].pronunciation}',
                                        style: const TextStyle(
                                          color: Color(0xFF667085))),
                                      const SizedBox(height: 11),
                                      Text(
                                        wordInsightFor(_cards[index].id)
                                            ?.explanation ??
                                            _cards[index].translation,
                                        style: const TextStyle(
                                          color: navy, height: 1.6)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ],
                          ),
                        ),
                        if (_saveError != null) ...[
                          Text(_saveError!, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 9),
                        ],
                        if (selected != null &&
                            choices[selected!] == _cards[index].translation &&
                            _saveError == null)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF21865B)),
                                SizedBox(width: 8),
                                Text('إجابة صحيحة! الانتقال تلقائيًا...',
                                  style: TextStyle(
                                    color: Color(0xFF21865B),
                                    fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        if (selected != null &&
                            (choices[selected!] != _cards[index].translation ||
                                _saveError != null))
                          FilledButton(
                            key: const Key('quiz_next'),
                            onPressed: _saving ? null : next,
                            style: FilledButton.styleFrom(
                              backgroundColor: orange,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(_saving ? 'جارٍ حفظ النتيجة...'
                              : index + 1 == _cards.length ? 'عرض النتيجة' : 'السؤال التالي'),
                          ),
                      ]),
                    ),
        ),
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
  Set<String> favorites = <String>{};
  bool favoritesOnly = false;
  bool favoritesLoading = true;
  bool savingFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final saved = await FavoriteWordsRepository.load();
      if (!mounted) {
        return;
      }
      final knownIds = allCards.map((card) => card.id).toSet();
      setState(() {
        favorites = saved.intersection(knownIds);
        favoritesLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => favoritesLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر تحميل الكلمات المفضلة')),
      );
    }
  }

  Future<void> _toggleFavorite(String id) async {
    if (savingFavorite || favoritesLoading) {
      return;
    }
    final previous = favorites;
    final updated = FavoriteWordsRepository.toggle(previous, id);
    setState(() {
      favorites = updated;
      savingFavorite = true;
    });
    try {
      await FavoriteWordsRepository.save(updated);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => favorites = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر حفظ المفضلة، حاول مجددًا')),
      );
    } finally {
      if (mounted) {
        setState(() => savingFavorite = false);
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = allCards.where((card) {
      if (favoritesOnly && !favorites.contains(card.id)) {
        return false;
      }
      return matchesVocabularyQuery(card, query);
    }).toList();
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Row(
                children: [
                  ChoiceChip(
                    key: const Key('all_words_filter'),
                    label: const Text('جميع الكلمات'),
                    selected: !favoritesOnly,
                    onSelected: (_) => setState(() => favoritesOnly = false),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    key: const Key('favorites_filter'),
                    label: Text('المفضلة (${favorites.length})'),
                    selected: favoritesOnly,
                    avatar: const Icon(Icons.bookmark_rounded, size: 18),
                    onSelected: (_) => setState(() => favoritesOnly = true),
                  ),
                ],
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
                        Text('جرّب كلمة أخرى أو أضف كلمات إلى المفضلة',
                          style: TextStyle(color: Color(0xFF667085))),
                      ],
                    ))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                      itemCount: results.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final card = results[index];
                        final insight = wordInsightFor(card.id);
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
                            trailing: IconButton(
                              key: Key('favorite_${card.id}'),
                              tooltip: favorites.contains(card.id)
                                  ? 'إزالة من المفضلة'
                                  : 'إضافة إلى المفضلة',
                              onPressed: savingFavorite || favoritesLoading
                                  ? null
                                  : () => _toggleFavorite(card.id),
                              icon: Icon(
                                favorites.contains(card.id)
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                color: favorites.contains(card.id)
                                    ? const Color(0xFFFF653B)
                                    : const Color(0xFF667085),
                              ),
                            ),
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
                              if (insight != null) ...[
                                const SizedBox(height: 16),
                                WordInsightDetails(
                                  insight: insight,
                                  compact: true,
                                ),
                              ],
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
