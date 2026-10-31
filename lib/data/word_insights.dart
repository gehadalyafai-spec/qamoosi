/// Additional beginner-friendly explanations for the existing offline cards.
///
/// IDs intentionally match CardEntry.id. Changing an ID would break saved
/// progress, review schedules and favorites. These texts are editorial content,
/// never executable instructions.
class WordInsight {
  const WordInsight({
    required this.explanation,
    required this.projectUse,
    required this.practiceQuestion,
  });

  final String explanation;
  final String projectUse;
  final String practiceQuestion;
}

const wordInsights = <String, WordInsight>{
  "variable": WordInsight(
    explanation: "المتغير مكان نضع فيه قيمة باسم واضح، ويمكن أن تتغير هذه القيمة أثناء تشغيل البرنامج.",
    projectUse: "في قاموسي يتغير رقم البطاقة الحالية كلما انتقلت إلى كلمة جديدة.",
    practiceQuestion: "ما المتغير المناسب لحفظ عدد الكلمات التي أتقنتها؟",
  ),
  "constant": WordInsight(
    explanation: "الثابت قيمة نحددها مرة واحدة ولا نعيد تغييرها بعد تعريفها.",
    projectUse: "يمكن تخزين اسم التطبيق «قاموسي» في ثابت ليستخدم في أكثر من شاشة.",
    practiceQuestion: "متى تفضّل استخدام ثابت بدل متغير؟",
  ),
  "function": WordInsight(
    explanation: "الدالة مجموعة أوامر لها اسم، نستدعيها لتنفيذ مهمة محددة بدل تكرار الكود.",
    projectUse: "يمكن إنشاء دالة تحسب نسبة التقدم في الدرس ثم استخدامها في الصفحة الرئيسية.",
    practiceQuestion: "ما المهمة التي يمكن تحويلها إلى دالة في تطبيقك؟",
  ),
  "parameter": WordInsight(
    explanation: "المعامل اسم متغير يُكتب في تعريف الدالة ليستقبل قيمة عند استدعائها.",
    projectUse: "دالة عرض درس قد تستقبل اسم الدرس في معامل اسمه lessonTitle.",
    practiceQuestion: "إذا عرّفت دالة باسم greet(name)، فما المعامل؟",
  ),
  "return": WordInsight(
    explanation: "تعليمة تُنهي تنفيذ الدالة غالبًا وتُرجع نتيجة إلى المكان الذي استدعاها.",
    projectUse: "دالة حساب التقدم ترجع نسبة مثل 0.6 لاستخدامها في شريط الإنجاز.",
    practiceQuestion: "ما القيمة التي ينبغي أن ترجعها دالة جمع رقمين؟",
  ),
  "bug": WordInsight(
    explanation: "الخلل البرمجي سلوك غير صحيح أو نتيجة غير متوقعة في التطبيق.",
    projectUse: "ظهور عدد خاطئ للكلمات المستحقة للمراجعة يعد خللًا يحتاج إصلاحًا.",
    practiceQuestion: "إذا لم يُحفظ تقدمك بعد الضغط على «عرفتها»، فما المشكلة؟",
  ),
  "debug": WordInsight(
    explanation: "تصحيح الأخطاء عملية تتبّع سبب الخلل وفهمه ثم إصلاحه والتحقق من الحل.",
    projectUse: "نفحص سجل تشغيل Flutter لمعرفة سبب توقف شاشة البحث أو ظهور استثناء.",
    practiceQuestion: "ما أول شيء ستراجعه عند ظهور رسالة خطأ؟",
  ),
  "syntax": WordInsight(
    explanation: "الصياغة البرمجية هي قواعد كتابة التعليمات التي تقبلها لغة البرمجة.",
    projectUse: "نسيان قوس أو كتابة فاصلة في غير موضعها قد يسبب خطأ في الصياغة.",
    practiceQuestion: "لماذا قد يرفض المترجم كودًا فيه قوس ناقص؟",
  ),
  "build": WordInsight(
    explanation: "البناء يحوّل ملفات المشروع ومكوناته إلى نسخة قابلة للتشغيل أو التوزيع.",
    projectUse: "عند بناء تطبيق Flutter للأندرويد قد ينتج ملف APK للتجربة.",
    practiceQuestion: "ما الفرق بين تعديل الكود وبناء نسخة منه؟",
  ),
  "release": WordInsight(
    explanation: "الإصدار نسخة من التطبيق نُعدّها للمستخدمين بعد الاختبار والتجهيز.",
    projectUse: "بعد التأكد من عمل قاموسي يمكن إعداد إصدار لنشره في متجر التطبيقات.",
    practiceQuestion: "لماذا نختبر التطبيق قبل نشر إصدار جديد؟",
  ),
  "repository": WordInsight(
    explanation: "المستودع مكان تُدار فيه ملفات المشروع وتاريخ تغييراتها باستخدام Git.",
    projectUse: "يمكن حفظ كود قاموسي في مستودع GitHub ومراجعته مع كل تحديث.",
    practiceQuestion: "لماذا يفيد وجود تاريخ للتغييرات في المستودع؟",
  ),
  "branch": WordInsight(
    explanation: "الفرع مسار مستقل للعمل على تعديلات دون التأثير فورًا في الفرع الرئيسي.",
    projectUse: "يمكن تطوير ميزة البطاقات على فرع development قبل دمجها في main.",
    practiceQuestion: "أين تجرّب ميزة جديدة قبل ضمها للإصدار المستقر؟",
  ),
  "commit": WordInsight(
    explanation: "الالتزام أو التسجيل هو حفظ لقطة من تغييرات الملفات في تاريخ Git مع وصف.",
    projectUse: "بعد إضافة اختبار جديد نسجل التعديل برسالة تشرح ما تغيّر.",
    practiceQuestion: "ما فائدة كتابة رسالة واضحة عند تسجيل التغييرات؟",
  ),
  "push": WordInsight(
    explanation: "الرفع يرسل التغييرات المسجلة محليًا إلى المستودع البعيد.",
    projectUse: "بعد حفظ التعديل في Git يمكن رفعه إلى GitHub ليظهر في المستودع.",
    practiceQuestion: "هل يكفي حفظ الملف محليًا ليظهر التعديل على GitHub؟",
  ),
  "pull": WordInsight(
    explanation: "الجلب والدمج يجلبان تغييرات الفرع البعيد إلى نسختك المحلية.",
    projectUse: "قبل تشغيل أحدث نسخة من قاموسي نجلب تحديثات فرع development.",
    practiceQuestion: "متى تحتاج إلى جلب أحدث تعديلات الفريق؟",
  ),
  "file": WordInsight(
    explanation: "الملف عنصر يحفظ بيانات أو نصًا أو كودًا باسم وامتداد.",
    projectUse: "قد يحتوي ملف main.dart على نقطة بدء تطبيق Flutter.",
    practiceQuestion: "أين يمكن أن تحفظ كود صفحة جديدة؟",
  ),
  "folder": WordInsight(
    explanation: "المجلد حاوية لتنظيم الملفات والمجلدات الأخرى داخل المشروع.",
    projectUse: "يمكن جمع شاشات التطبيق في مجلد features لتسهيل الوصول إليها.",
    practiceQuestion: "كيف تنظم ملفات الاختبارات بعيدًا عن شاشات التطبيق؟",
  ),
  "path": WordInsight(
    explanation: "المسار هو العنوان الذي يحدد مكان ملف أو مجلد داخل النظام.",
    projectUse: "المسار lib/main.dart يحدد ملفًا داخل مجلد lib في المشروع.",
    practiceQuestion: "كيف تحدد مكان ملف اختبارات داخل مجلد test؟",
  ),
  "save": WordInsight(
    explanation: "الحفظ يكتب التغييرات إلى الملف حتى تبقى بعد إغلاق المحرر.",
    projectUse: "بعد تعديل كود Flutter نحفظ الملف قبل إعادة بناء التطبيق.",
    practiceQuestion: "ماذا يحدث لو أغلقت المحرر دون حفظ التغييرات؟",
  ),
  "open": WordInsight(
    explanation: "الفتح يجعل ملفًا أو مجلدًا أو مشروعًا متاحًا للعرض والتعديل.",
    projectUse: "نفتح مجلد مشروع قاموسي في VS Code لقراءة ملفاته.",
    practiceQuestion: "ما الذي يجب فتحه أولًا لرؤية ملفات المشروع؟",
  ),
  "server": WordInsight(
    explanation: "الخادم برنامج أو جهاز يوفّر خدمات أو بيانات لأجهزة أو برامج أخرى.",
    projectUse: "قد يرسل تطبيق المتجر طلبًا إلى خادم ليجلب حالة الطلب.",
    practiceQuestion: "أي طرف يستقبل الطلب ويعيد البيانات عادةً؟",
  ),
  "client": WordInsight(
    explanation: "العميل برنامج يطلب خدمة أو بيانات من الخادم ثم يعرض النتيجة.",
    projectUse: "تطبيق الجوال الذي يعرض المنتجات يعد عميلًا يتواصل مع خادم المتجر.",
    practiceQuestion: "من يرسل الطلب عند فتح صفحة المنتجات؟",
  ),
  "database": WordInsight(
    explanation: "قاعدة البيانات نظام منظم لحفظ المعلومات والبحث عنها وتحديثها.",
    projectUse: "يمكن تخزين معلومات المنتجات والطلبات في قاعدة بيانات مرتبطة بالخادم.",
    practiceQuestion: "لماذا لا يناسب وضع آلاف الطلبات داخل متغير واحد؟",
  ),
  "api": WordInsight(
    explanation: "واجهة برمجة التطبيقات قواعد ونقاط اتصال تتيح لبرامج مختلفة تبادل البيانات.",
    projectUse: "قد يستخدم تطبيق سلة API لقراءة بيانات الطلبات من خادم المتجر.",
    practiceQuestion: "كيف يحصل تطبيق الجوال على بيانات من خدمة خارجية؟",
  ),
  "request": WordInsight(
    explanation: "الطلب رسالة يرسلها عميل إلى خدمة ليطلب بيانات أو إجراءً محددًا.",
    projectUse: "عند الضغط على «طلباتي» قد يرسل التطبيق طلبًا لجلب قائمة الطلبات.",
    practiceQuestion: "ماذا ينتظر العميل عادةً بعد إرسال الطلب؟",
  ),
  "run": WordInsight(
    explanation: "التشغيل يبدأ تنفيذ البرنامج لتتمكن من استخدامه أو تجربته.",
    projectUse: "الأمر flutter run يشغّل تطبيق قاموسي في وضع التطوير على جهاز مناسب.",
    practiceQuestion: "ما الخطوة اللازمة لتجربة تغييرك على شاشة التطبيق؟",
  ),
  "compile": WordInsight(
    explanation: "الترجمة البرمجية تحوّل الشيفرة المصدرية إلى تمثيل آخر يفهمه النظام أو بيئة التشغيل.",
    projectUse: "خلال تجهيز تطبيق Flutter قد تُترجم أجزاء من الكود ضمن خطوات البناء.",
    practiceQuestion: "هل الترجمة البرمجية هي نفسها تشغيل التطبيق؟",
  ),
  "output": WordInsight(
    explanation: "المخرجات هي البيانات أو النتائج التي ينتجها البرنامج بعد المعالجة.",
    projectUse: "بعد حساب عدد الكلمات المتقنة يعرض البرنامج الرقم في شاشة الإنجازات.",
    practiceQuestion: "ما المخرجات المتوقعة من دالة تجمع رقمين؟",
  ),
  "input": WordInsight(
    explanation: "المدخلات بيانات يستقبلها البرنامج من مستخدم أو ملف أو خدمة.",
    projectUse: "الكلمة التي تكتبها في مربع البحث تعد مدخلًا يستخدمه التطبيق لتصفية النتائج.",
    practiceQuestion: "ما نوع المدخلات في حقل البحث عن الكلمات؟",
  ),
  "result": WordInsight(
    explanation: "النتيجة قيمة أو معلومة نحصل عليها بعد تنفيذ عملية أو اختبار.",
    projectUse: "قد تعرض صفحة الاختبار نتيجة 5 من 6 بعد الإجابة عن الأسئلة.",
    practiceQuestion: "ما الفرق بين إدخال إجابتك والنتيجة التي تظهر بعدها؟",
  ),
};

WordInsight? wordInsightFor(String cardId) => wordInsights[cardId];
