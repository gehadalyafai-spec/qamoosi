/// Original, fully offline, authored programming exercises.
///
/// Exercises test choosing a missing statement or arranging implementation
/// steps. They are educational examples and never execute input or source code.
enum CodeLabKind { missingLine, orderSteps }

class CodeLabExercise {
  const CodeLabExercise.missing({
    required this.id,
    required this.title,
    required this.prompt,
    required this.snippet,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.term,
    required this.translation,
  }) : kind = CodeLabKind.missingLine,
       steps = const [];

  const CodeLabExercise.order({
    required this.id,
    required this.title,
    required this.prompt,
    required this.steps,
    required this.explanation,
    required this.term,
    required this.translation,
  }) : kind = CodeLabKind.orderSteps,
       snippet = '',
       options = const [],
       correctAnswer = '';

  final String id;
  final String title;
  final String prompt;
  final CodeLabKind kind;
  final String snippet;
  final List<String> options;
  final String correctAnswer;
  final List<String> steps;
  final String explanation;
  final String term;
  final String translation;

  bool get hasValidAnswer => kind == CodeLabKind.missingLine
      ? options.length == 4 &&
        options.toSet().length == 4 &&
        options.contains(correctAnswer) &&
        snippet.contains('_____')
      : steps.length >= 3 && steps.toSet().length == steps.length;

  /// Position in the *correct* list, shown in a deliberately different order.
  List<int> get shuffledStepIndices {
    if (steps.length < 3) return [for (var i = 0; i < steps.length; i++) i];
    return [for (var i = 2; i < steps.length; i++) i, 0, 1];
  }

  bool matchesOrderedSteps(List<int> selection) {
    if (kind != CodeLabKind.orderSteps ||
        selection.length != steps.length ||
        selection.toSet().length != steps.length) {
      return false;
    }
    for (var i = 0; i < steps.length; i++) {
      if (selection[i] != i) return false;
    }
    return true;
  }
}

const codeLabCatalog = <CodeLabExercise>[
  CodeLabExercise.missing(
    id: "dart_variable",
    title: "متغير في Dart",
    prompt: "اختر التعليمة التي تعرّف عددًا صحيحًا قابلًا للتغيير",
    snippet: "void main() {\n  _____\n  print(count);\n}",
    options: ["int count = 1;", "const count = 1;", "return count;", "print(count);"],
    correctAnswer: "int count = 1;",
    explanation: "استخدم int عند تعريف متغير يخزن عددًا صحيحًا، ويمكن تغيير قيمته بعد ذلك.",
    term: "Variable",
    translation: "متغير",
  ),
  CodeLabExercise.missing(
    id: "dart_return",
    title: "نتيجة الدالة",
    prompt: "أي سطر يعيد حاصل جمع العددين إلى من استدعى الدالة؟",
    snippet: "int add(int a, int b) {\n  _____\n}",
    options: ["print(a + b);", "return a + b;", "final a = b;", "void add();"],
    correctAnswer: "return a + b;",
    explanation: "return تُعيد قيمة للدالة، أما print فيعرضها فقط ولا يعيدها للمستدعي.",
    term: "Return",
    translation: "إرجاع قيمة",
  ),
  CodeLabExercise.missing(
    id: "dart_list",
    title: "إضافة عنصر لقائمة",
    prompt: "أكمل التعليمة لإضافة كلمة إلى القائمة.",
    snippet: "final words = <String>[];\n_____\nprint(words);",
    options: ["words.add('Flutter');", "words.remove('Flutter');", "words.clear();", "words.length;"],
    correctAnswer: "words.add('Flutter');",
    explanation: "تستخدم add لإضافة عنصر جديد إلى List قابلة للتعديل.",
    term: "List",
    translation: "قائمة",
  ),
  CodeLabExercise.missing(
    id: "dart_condition",
    title: "التحقق من الشرط",
    prompt: "اختر شرطًا يعرض الرسالة فقط إذا كان المتعلم أتقن خمس كلمات أو أكثر.",
    snippet: "if (_____) {\n  print('Great progress');\n}",
    options: ["known == 0", "known >= 5", "known < 5", "known = 5"],
    correctAnswer: "known >= 5",
    explanation: "العامل >= يعني أكبر من أو يساوي، ويُستخدم للمقارنة وليس لتعيين قيمة.",
    term: "Boolean",
    translation: "قيمة منطقية",
  ),
  CodeLabExercise.missing(
    id: "dart_null",
    title: "قيمة اختيارية",
    prompt: "ما السطر الصحيح للتعامل مع اسم قد تكون قيمته null؟",
    snippet: "String? name;\nfinal display = _____;\nprint(display);",
    options: ["name ?? 'زائر'", "name = null;", "name! + null", "return null;"],
    correctAnswer: "name ?? 'زائر'",
    explanation: "العامل ?? يعيد القيمة البديلة عندما تكون القيمة الأساسية null.",
    term: "Nullable",
    translation: "قابل لأن يكون فارغًا",
  ),
  CodeLabExercise.missing(
    id: "dart_async",
    title: "انتظار عملية غير متزامنة",
    prompt: "كيف تنتظر تحميل اسم المستخدم قبل استخدامه؟",
    snippet: "Future<void> showName() async {\n  final name = _____;\n  print(name);\n}",
    options: ["await loadName()", "return Future;", "print(loadName())", "loadName = false"],
    correctAnswer: "await loadName()",
    explanation: "await تنتظر نتيجة Future داخل دالة async من دون إيقاف بقية التطبيق.",
    term: "Future",
    translation: "نتيجة مستقبلية",
  ),
  CodeLabExercise.missing(
    id: "flutter_widget",
    title: "عنصر واجهة Flutter",
    prompt: "ما المكوّن المناسب لعرض نص في شاشة Flutter؟",
    snippet: "Widget build(BuildContext context) {\n  return _____;\n}",
    options: ["Text('قاموسي')", "print('قاموسي')", "String('قاموسي')", "return void;"],
    correctAnswer: "Text('قاموسي')",
    explanation: "Text هو Widget لعرض النصوص داخل شجرة واجهة Flutter.",
    term: "Widget",
    translation: "عنصر واجهة",
  ),
  CodeLabExercise.missing(
    id: "flutter_state",
    title: "تحديث الواجهة",
    prompt: "ما التعليمة الصحيحة لإعلام Flutter بتغيير حالة العدّاد؟",
    snippet: "void increase() {\n  _____\n}",
    options: ["setState(() => count++);", "count == count + 1;", "print(count);", "const count = 0;"],
    correctAnswer: "setState(() => count++);",
    explanation: "setState يبلغ Flutter بتغيّر البيانات حتى تُعاد عملية بناء العناصر المتأثرة.",
    term: "State",
    translation: "حالة",
  ),
  CodeLabExercise.missing(
    id: "git_branch",
    title: "فرع تطوير مستقل",
    prompt: "اختر أمر Git لإنشاء فرع جديد والانتقال إليه.",
    snippet: "# Branch: feature/quiz\n_____",
    options: ["git switch -c feature/quiz", "git merge feature/quiz", "git status feature/quiz", "git push origin main"],
    correctAnswer: "git switch -c feature/quiz",
    explanation: "الخيار -c ينشئ الفرع ثم ينتقل إليه، ما يساعد على تطوير الميزة منفصلة.",
    term: "Branch",
    translation: "فرع",
  ),
  CodeLabExercise.missing(
    id: "sql_select",
    title: "قراءة البيانات من SQL",
    prompt: "ما عبارة SQL التي تجلب اسم المنتج عندما يكون المخزون أكبر من صفر؟",
    snippet: "_____\n-- Show products available in stock",
    options: ["SELECT name FROM products WHERE stock > 0;", "DELETE FROM products;", "UPDATE products SET stock = 0;", "DROP TABLE products;"],
    correctAnswer: "SELECT name FROM products WHERE stock > 0;",
    explanation: "SELECT يقرأ الأعمدة المطلوبة، وWHERE يحدد الصفوف المطابقة للشرط.",
    term: "Query",
    translation: "استعلام",
  ),
  CodeLabExercise.missing(
    id: "api_request",
    title: "استدعاء API",
    prompt: "ما طريقة HTTP المناسبة لقراءة قائمة المنتجات دون طلب تعديلها؟",
    snippet: "_____ /api/products HTTP/1.1",
    options: ["POST", "GET", "PATCH", "DELETE"],
    correctAnswer: "GET",
    explanation: "GET تُستخدم عادة لقراءة البيانات من الخادم دون تعديلها.",
    term: "GET",
    translation: "طلب قراءة",
  ),
  CodeLabExercise.missing(
    id: "error_handling",
    title: "معالجة الاستثناء",
    prompt: "ما الجزء الذي يعالج استثناءً قد يحدث أثناء تنفيذ العملية؟",
    snippet: "try {\n  await loadCards();\n} _____ {\n  print(error);\n}",
    options: ["onDone (error)", "catch (error)", "return (error)", "if (true)"],
    correctAnswer: "catch (error)",
    explanation: "catch يتلقى الاستثناء حتى يستطيع البرنامج التعامل معه بصورة مناسبة.",
    term: "Exception",
    translation: "استثناء",
  ),
  CodeLabExercise.order(
    id: "git_workflow",
    title: "تسجيل التغييرات في Git",
    prompt: "رتّب الخطوات لرفع ميزة جديدة إلى المستودع البعيد.",
    steps: ["أنشئ فرع تطوير جديد", "عدّل الملفات واختبر التغيير", "نفّذ git add ثم git commit", "ارفع الفرع باستخدام git push"],
    explanation: "اعمل في فرع منفصل، ثم افحص التعديلات وسجّلها قبل رفعها للمستودع البعيد.",
    term: "Commit",
    translation: "تسجيل تغييرات",
  ),
  CodeLabExercise.order(
    id: "flutter_build",
    title: "تجهيز نسخة Flutter",
    prompt: "رتّب خطوات التحقق المعتادة قبل إنتاج نسخة تطبيق أندرويد.",
    steps: ["ثبّت الاعتمادات باستخدام flutter pub get", "تحقق من الكود باستخدام flutter analyze", "شغّل الاختبارات باستخدام flutter test", "ابنِ النسخة باستخدام flutter build apk"],
    explanation: "التحليل والاختبار قبل البناء يساعدان على اكتشاف المشكلات مبكرًا.",
    term: "Build",
    translation: "بناء التطبيق",
  ),
  CodeLabExercise.order(
    id: "api_flow",
    title: "دورة طلب API",
    prompt: "رتّب الرحلة المعتادة لطلب بيانات من واجهة API.",
    steps: ["يرسل العميل طلب HTTP", "يستقبل الخادم الطلب ويتحقق منه", "يعالج الخادم الطلب ويقرأ البيانات عند الحاجة", "يرسل الخادم استجابة HTTP إلى العميل"],
    explanation: "العميل يبدأ الطلب، والخادم يتحقق ويعالج ويرجع الاستجابة.",
    term: "Request",
    translation: "طلب",
  ),
  CodeLabExercise.order(
    id: "debug_flow",
    title: "إصلاح خطأ برمجي",
    prompt: "ما الترتيب الأنسب لمعالجة خلل ظهر في التطبيق؟",
    steps: ["أعد إنتاج الخطأ لتتأكد من ظهوره", "افحص السجلات وحدد السبب", "صحّح الكود المرتبط بالمشكلة", "أعد تشغيل الاختبارات وتحقق من الإصلاح"],
    explanation: "لا تبدأ بتغيير الكود عشوائيًا؛ تحديد السبب ثم الاختبار يقلل عودة الخلل.",
    term: "Debug",
    translation: "تصحيح الأخطاء",
  ),
  CodeLabExercise.order(
    id: "data_migration",
    title: "تغيير مخطط البيانات",
    prompt: "رتّب الخطوات المعتادة لإجراء تغيير آمن على قاعدة بيانات.",
    steps: ["خطط للتعديل وجهّز نسخة احتياطية مناسبة", "اكتب ملفات الترحيل المطلوبة", "اختبر الترحيل على بيئة غير إنتاجية", "نفّذ النشر بعد مراجعة النتائج"],
    explanation: "اختبار Migration قبل تطبيقها على الإنتاج يقلل مخاطر تلف البيانات.",
    term: "Migration",
    translation: "ترحيل قاعدة بيانات",
  ),
  CodeLabExercise.order(
    id: "ui_feature",
    title: "إضافة ميزة واجهة",
    prompt: "رتّب خطوات بناء ميزة بسيطة في واجهة Flutter.",
    steps: ["حدد سلوك المستخدم والبيانات المطلوبة", "صمم Widget يعرض الحالة", "اربط الأزرار بتحديث الحالة", "اختبر التفاعل على أحجام شاشات مختلفة"],
    explanation: "تبدأ الميزة بفهم التدفق ثم تنفيذ الواجهة وربط حالتها والتحقق منها.",
    term: "Widget",
    translation: "عنصر واجهة",
  ),
  CodeLabExercise.order(
    id: "login_flow",
    title: "تسجيل دخول المستخدم",
    prompt: "رتّب التسلسل العام لطلب تسجيل دخول ضمن تطبيق.",
    steps: ["يدخل المستخدم بيانات الدخول", "يرسل التطبيق الطلب إلى خدمة المصادقة", "تتحقق الخدمة من البيانات والصلاحيات", "يعرض التطبيق نتيجة الدخول ويحدّث الجلسة"],
    explanation: "لا يكفي إدخال البيانات؛ تتحقق الخدمة من الهوية قبل منح الجلسة.",
    term: "Authentication",
    translation: "مصادقة",
  ),
  CodeLabExercise.order(
    id: "webhook_flow",
    title: "استقبال إشعار Webhook",
    prompt: "رتّب الخطوات في إشعار تحديث طلب بين نظامين.",
    steps: ["تتغير حالة الطلب في النظام الأول", "يُنشئ النظام الأول إشعار الحدث", "يرسل إشعار Webhook إلى النظام المستقبل", "يتحقق النظام المستقبل من الإشعار ويحدث بياناته"],
    explanation: "تُرسل أحداث Webhook تلقائيًا عند وقوع الحدث لتحديث الأنظمة المتصلة.",
    term: "Webhook",
    translation: "إشعار حدث",
  ),
  CodeLabExercise.order(
    id: "checkout_flow",
    title: "رحلة شراء إلكتروني",
    prompt: "رتّب مراحل رحلة شراء نموذجية في متجر إلكتروني.",
    steps: ["يختار العميل المنتجات ويضعها في السلة", "يراجع العميل الطلب والعنوان وطريقة الشحن", "يختار العميل وسيلة الدفع ويؤكد الطلب", "يتلقى العميل تأكيد إنشاء الطلب وبياناته"],
    explanation: "التأكد من محتوى السلة والعنوان يسبق تأكيد الطلب عادةً.",
    term: "Checkout",
    translation: "إتمام الشراء",
  ),
  CodeLabExercise.order(
    id: "offline_progress",
    title: "حفظ التقدم دون إنترنت",
    prompt: "رتّب خطوات تسجيل تقدم تعلم بطاقة داخل التطبيق.",
    steps: ["يختار المستخدم تقييمه للبطاقة", "يحدّث التطبيق حالة المراجعة محليًا", "يحفظ التطبيق التغيير في التخزين المحلي", "يعرض التطبيق التقدم الجديد في الواجهة"],
    explanation: "التخزين المحلي يحفظ التقدم حتى لا يحتاج التعلم إلى اتصال مستمر.",
    term: "Storage",
    translation: "تخزين",
  ),
  CodeLabExercise.order(
    id: "ci_pipeline",
    title: "دورة التكامل المستمر",
    prompt: "رتّب عملية التحقق التلقائي بعد رفع تغييرات مشروع.",
    steps: ["يرفع المطور التغييرات إلى GitHub", "تبدأ مهمة CI على الخادم", "يشغّل النظام تحليل الكود والاختبارات", "يُظهر النظام نتيجة الفحص للمطور"],
    explanation: "CI يساعد على اكتشاف الأخطاء آليًا قبل نشر التغيير للمستخدمين.",
    term: "CI",
    translation: "تكامل مستمر",
  ),
  CodeLabExercise.order(
    id: "release_process",
    title: "إصدار نسخة تطبيق",
    prompt: "رتّب خطوات تجهيز إصدار جديد بصورة منظمة.",
    steps: ["ثبّت الميزات المراد نشرها", "نفّذ اختبارات نهائية على النسخة", "أنشئ حزمة إصدار مناسبة للمنصة", "راجع بيانات الإصدار ثم انشره"],
    explanation: "الاختبارات النهائية تسبق بناء الإصدار وتوزيعه على المستخدمين.",
    term: "Release",
    translation: "إصدار للتوزيع",
  ),
];

/// Six balanced tasks in each session: three missing lines and three ordering
/// exercises. Twenty-four tasks are covered in four completed sessions before
/// repetition. The selection is independent from the legacy quiz rotation.
List<CodeLabExercise> buildCodeLabRound({
  required int completedAttempts,
  List<CodeLabExercise> catalog = codeLabCatalog,
  int questionCount = 6,
}) {
  if (questionCount <= 0 || catalog.isEmpty) return const [];
  final missing = catalog.where(
    (task) => task.kind == CodeLabKind.missingLine).toList();
  final ordered = catalog.where(
    (task) => task.kind == CodeLabKind.orderSteps).toList();
  final pool = <CodeLabExercise>[];
  final maxLength = missing.length > ordered.length
      ? missing.length : ordered.length;
  for (var i = 0; i < maxLength; i++) {
    if (i < missing.length) pool.add(missing[i]);
    if (i < ordered.length) pool.add(ordered[i]);
  }
  if (pool.isEmpty) return const [];
  final attempt = completedAttempts < 0 ? 0 : completedAttempts;
  final count = questionCount < pool.length ? questionCount : pool.length;
  final start = ((attempt % pool.length) * (count % pool.length)) % pool.length;
  return List<CodeLabExercise>.unmodifiable([
    for (var i = 0; i < count; i++) pool[(start + i) % pool.length],
  ]);
}
