/// Offline, scenario-based computer terminology practice.
///
/// Questions are grouped in pairs matching the six existing vocabulary
/// lessons. Each completed session asks one question per lesson, and the next
/// session alternates between the two sets. This leaves the vocabulary quiz,
/// saved flashcard progress, and reviews unchanged.
class PracticeQuestion {
  const PracticeQuestion({
    required this.id,
    required this.lessonIndex,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String id;
  final int lessonIndex;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  bool isCorrect(int chosenIndex) => chosenIndex == correctIndex;
}

const practiceQuestions = <PracticeQuestion>[
  PracticeQuestion(
    id: "variable",
    lessonIndex: 0,
    prompt: "في قاموسي، يتغير عدد الكلمات المتقنة كلما تعلمت كلمة. كيف تحفظ هذا العدد في الكود؟",
    options: ["في ثابت لا يُغيّر","في متغير يمكن تحديثه","في صورة داخل المشروع","في طلب شبكة"],
    correctIndex: 1,
    explanation: "المتغير مناسب للقيم التي تتغير أثناء التشغيل، مثل عدد البطاقات المتقنة.",
  ),
  PracticeQuestion(
    id: "function",
    lessonIndex: 0,
    prompt: "تحتاج لحساب نسبة تقدم الدرس في أكثر من شاشة. ما الحل البرمجي الأنسب؟",
    options: ["تكرر الكود في كل شاشة","تلغي عرض النسبة","تنشئ دالة وتعيد استخدامها","تغير اسم المشروع"],
    correctIndex: 2,
    explanation: "الدالة تجمع المنطق في مكان واحد ليُستدعى من أكثر من شاشة.",
  ),
  PracticeQuestion(
    id: "bug",
    lessonIndex: 1,
    prompt: "صفحة إنجازاتي تعرض 12 بطاقة متقنة رغم أن المستخدم أتقن 3 فقط. ما وصف المشكلة؟",
    options: ["خلل برمجي يحتاج تتبعًا","نجاح عملية البناء","تغيير في اسم الفرع","نوع جديد من الملفات"],
    correctIndex: 0,
    explanation: "عندما يعطي التطبيق نتيجة غير صحيحة فهذا خلل، حتى لو لم يتوقف عن العمل.",
  ),
  PracticeQuestion(
    id: "test",
    lessonIndex: 1,
    prompt: "أصلحت مشكلة حفظ المفضلة. كيف تتحقق من أنها لن تتكرر؟",
    options: ["تغيّر لون الزر فقط","تحذف سجلات المشروع","تكتب اختبارًا للحفظ وإعادة الفتح","تغلق التطبيق دون تشغيله"],
    correctIndex: 2,
    explanation: "الاختبار الذي يحاكي حفظ الكلمة ثم إعادة فتح الصفحة يساعد على منع تكرار الخلل.",
  ),
  PracticeQuestion(
    id: "branch",
    lessonIndex: 2,
    prompt: "تريد تطوير ميزة جديدة دون التأثير مباشرة في النسخة المستقرة. ماذا تستخدم؟",
    options: ["ملفًا مؤقتًا بلا تاريخ","فرع Git مستقلًا","إعادة تسمية كل الملفات","حذف المستودع الرئيسي"],
    correctIndex: 1,
    explanation: "فرع Git يسمح بتطوير ميزة وتجربتها قبل دمجها في الفرع المستقر.",
  ),
  PracticeQuestion(
    id: "merge",
    lessonIndex: 2,
    prompt: "انتهيت من اختبار فرع التطوير وتريد جمع تغييراته مع الفرع الرئيسي. ما العملية؟",
    options: ["Compile","Print","Clone","Merge"],
    correctIndex: 3,
    explanation: "عملية Merge تدمج تغييرات فرع مع فرع آخر بعد مراجعتها.",
  ),
  PracticeQuestion(
    id: "folder",
    lessonIndex: 3,
    prompt: "لديك ملفات شاشات كثيرة وتريد تنظيمها داخل المشروع. ما الذي يساعدك؟",
    options: ["مجلدات تحمل أسماء واضحة","أرقام عشوائية للملفات","تكرار كل ملف مرتين","تغيير امتداد جميع الملفات"],
    correctIndex: 0,
    explanation: "تجميع الملفات ذات الصلة داخل مجلدات يجعل المشروع أوضح وأسهل صيانة.",
  ),
  PracticeQuestion(
    id: "extension",
    lessonIndex: 3,
    prompt: "الملف main.dart مكتوب بلغة Dart. أي جزء من اسمه يدل عادة على نوع الملف؟",
    options: ["main","الامتداد dart","عدد الحروف","مكان ظهور الملف"],
    correctIndex: 1,
    explanation: "الامتداد هو الجزء الذي يأتي عادة بعد النقطة، مثل .dart.",
  ),
  PracticeQuestion(
    id: "client",
    lessonIndex: 4,
    prompt: "تطبيق المتجر يرسل طلبًا إلى خادم لجلب المنتجات. ما دور تطبيق الجوال؟",
    options: ["عميل يطلب البيانات","خادم يخزن قاعدة البيانات","مترجم للغة Dart","أمر لنظام Git"],
    correctIndex: 0,
    explanation: "العميل يرسل الطلب ويعرض البيانات، بينما تتولى خدمة الخادم الاستجابة.",
  ),
  PracticeQuestion(
    id: "response",
    lessonIndex: 4,
    prompt: "أرسل تطبيق المتجر طلبًا لقائمة المنتجات، فعادت بيانات مع رمز 200. ماذا نسمي ما عاد إليه؟",
    options: ["Branch","Folder","Response","Commit"],
    correctIndex: 2,
    explanation: "الاستجابة هي ما يعيده الخادم بعد الطلب، وقد تتضمن بيانات ورمز حالة.",
  ),
  PracticeQuestion(
    id: "print",
    lessonIndex: 5,
    prompt: "تريد معرفة قيمة متغير أثناء فحص برنامج بسيط. أي تعليمة تعرضها في المخرجات؟",
    options: ["git merge","print(value)","flutter build","const فقط"],
    correctIndex: 1,
    explanation: "يمكن استخدام print لطباعة قيمة في المخرجات وفهم ما يحدث في البرنامج.",
  ),
  PracticeQuestion(
    id: "terminal",
    lessonIndex: 5,
    prompt: "تريد تنفيذ الأمر flutter test داخل VS Code. أين تكتبه؟",
    options: ["داخل اسم الملف","في مربع البحث عن كلمة","في صورة التطبيق","في الطرفية Terminal"],
    correctIndex: 3,
    explanation: "الطرفية هي المكان المناسب لكتابة أوامر Flutter وGit ومشاهدة نتائجها.",
  ),
];

/// Return one scenario per lesson. The input counts *completed* sessions only.
List<PracticeQuestion> buildPracticeSession(int completedAttempts) {
  final variant = completedAttempts < 0 ? 0 : completedAttempts % 2;
  return [
    for (var lessonIndex = 0; lessonIndex < 6; lessonIndex++)
      practiceQuestions[lessonIndex * 2 + variant],
  ];
}
