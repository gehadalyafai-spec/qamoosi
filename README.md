# قاموسي | Qamoosi

نواة تطبيق بطاقات تعليمية عربية باستخدام Flutter، أول محتوى: الإنجليزية التقنية.

## ما يعمل الآن
- شاشة رئيسية وقائمة دروس.
- 15 بطاقة تجريبية موزعة على 3 دروس.
- قلب البطاقات لعرض المعنى والنطق المكتوب والمثال.
- حفظ الكلمات التي تم فهمها باستخدام SharedPreferences على الجهاز.
- اختبار Widget مبدئي.

## ما لم ينفذ بعد
- النطق الصوتي، الاختبارات التفاعلية، المراجعة المتباعدة، SQLite/Drift، البحث، النسخ الاحتياطي، تعدد المواد، الإشعارات.
- هذا **نموذج تأسيسي** وليس الإصدار 1.0 المكتمل.

## التشغيل
1. ثبّت Flutter وAndroid SDK.
2. انسخ المستودع وافتح الطرفية داخله.
3. نفّذ `flutter create --platforms=android,web .` لإنشاء ملفات المنصات القياسية (إن لم تكن موجودة).
4. نفّذ `flutter pub get` ثم `flutter test` ثم `flutter run`.
5. لإنشاء APK: `flutter build apk --release`.

> لم تتوفر أدوات Flutter في بيئة إنشاء الحزمة، ولذلك لم تُشغّل الاختبارات أو عملية بناء APK هنا. يلزم التحقق على جهاز التطوير.

## الهيكل التالي المقترح
- `lib/core/`: theme, router, storage
- `lib/features/library/`: subjects, courses, lessons
- `lib/features/study/`: flashcards, sessions
- `lib/features/review/`: spaced repetition
- `lib/features/progress/`: analytics
- `lib/features/settings/`: preferences and backups
