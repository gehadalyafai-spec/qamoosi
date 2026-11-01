/// A focused practice mode that does not overwrite any saved quiz results.
/// Unlike ordinary vocabulary translation quizzes, advanced questions are
/// author-reviewed code cases with a single intended technical concept.
enum QuizDifficulty { easy, intermediate, advanced }

extension QuizDifficultyDetails on QuizDifficulty {
  String get label => switch (this) {
    QuizDifficulty.easy => 'سهل',
    QuizDifficulty.intermediate => 'متوسط',
    QuizDifficulty.advanced => 'متقدم',
  };

  String get description => switch (this) {
    QuizDifficulty.easy => 'اختر الترجمة العربية الصحيحة للكلمة',
    QuizDifficulty.intermediate => 'اختر المصطلح المناسب لموقف عملي',
    QuizDifficulty.advanced => 'اقرأ الكود أو الأمر وافهم المفهوم الذي يمثله',
  };

  String get storageId => 'difficulty_$name';
}

class TechnicalCodeScenario {
  const TechnicalCodeScenario({required this.code, required this.question});
  final String code;
  final String question;
}

const advancedCodeScenarios = <String, TechnicalCodeScenario>{
  "variable": TechnicalCodeScenario(
    code: "int score = 0;\nscore = score + 1;",
    question: "ما المفهوم المستخدم لحفظ قيمة تتغير أثناء تشغيل البرنامج؟",
  ),
  "constant": TechnicalCodeScenario(
    code: "const maxCards = 6;\nprint(maxCards);",
    question: "ما المفهوم الذي يصف قيمة لا يعاد تعيينها بعد تعريفها؟",
  ),
  "function": TechnicalCodeScenario(
    code: "int doubleIt(int value) => value * 2;",
    question: "ما اسم الجزء البرمجي الذي يجمع خطوات قابلة للاستدعاء؟",
  ),
  "parameter": TechnicalCodeScenario(
    code: "void greet(String name) {\n  print(name);\n}",
    question: "ما اسم «name» داخل تعريف الدالة؟",
  ),
  "return": TechnicalCodeScenario(
    code: "int sum(int a, int b) {\n  return a + b;\n}",
    question: "ما التعليمة التي تعيد نتيجة الدالة إلى المستدعي؟",
  ),
  "string": TechnicalCodeScenario(
    code: "final city = 'Jeddah';",
    question: "ما نوع البيانات النصية المحفوظة بين علامات الاقتباس؟",
  ),
  "integer": TechnicalCodeScenario(
    code: "final amount = 42;",
    question: "ما نوع البيانات العددية من دون جزء عشري؟",
  ),
  "boolean": TechnicalCodeScenario(
    code: "bool loggedIn = false;",
    question: "ما نوع البيانات التي تقبل true أو false؟",
  ),
  "list": TechnicalCodeScenario(
    code: "final tags = ['dart', 'flutter'];\nprint(tags[0]);",
    question: "ما بنية البيانات المرتبة التي يمكن الوصول لعناصرها بمؤشر؟",
  ),
  "object": TechnicalCodeScenario(
    code: "final now = DateTime.now();\nprint(now.year);",
    question: "ما المفهوم الذي تصفه قيمة لها خصائص وسلوك مرتبطان بنوعها؟",
  ),
  "exception": TechnicalCodeScenario(
    code: "throw FormatException('Invalid value');",
    question: "ما المصطلح الذي يصف حالة غير اعتيادية يمكن رميها ومعالجتها؟",
  ),
  "test": TechnicalCodeScenario(
    code: "test('sum', () {\n  expect(2 + 2, 4);\n});",
    question: "ما نوع النشاط الذي يتحقق من النتيجة المتوقعة للكود؟",
  ),
  "branch": TechnicalCodeScenario(
    code: "git switch -c feature/search",
    question: "ما المفهوم الذي يسمح بتطوير ميزة على مسار مستقل من Git؟",
  ),
  "commit": TechnicalCodeScenario(
    code: "git add .\ngit commit -m 'Add lesson'",
    question: "ما العملية التي تسجل لقطة تغييرات في تاريخ Git؟",
  ),
  "repository": TechnicalCodeScenario(
    code: "git clone https://example.org/team/project.git",
    question: "ما اسم الحاوية التي تضم ملفات المشروع وتاريخ إصداراته؟",
  ),
  "push": TechnicalCodeScenario(
    code: "git push origin development",
    question: "ما العملية التي ترفع تغييرات محلية إلى مستودع بعيد؟",
  ),
  "pull": TechnicalCodeScenario(
    code: "git pull origin development",
    question: "ما العملية التي تجلب وتدمج تغييرات الفرع البعيد؟",
  ),
  "merge": TechnicalCodeScenario(
    code: "git merge feature/search",
    question: "ما العملية التي تجمع تغييرات فرع مع فرع آخر؟",
  ),
  "server": TechnicalCodeScenario(
    code: "app.get('/health', (req, res) => res.send('OK'));",
    question: "ما المكوّن الذي يستقبل طلبات العملاء ويعيد استجابات؟",
  ),
  "client": TechnicalCodeScenario(
    code: "final result = await http.get(uri);",
    question: "ما الطرف الذي يرسل طلبًا لخدمة بعيدة؟",
  ),
  "database": TechnicalCodeScenario(
    code: "INSERT INTO cards (word) VALUES ('Dart');",
    question: "ما النظام الذي يخزن السجلات لاسترجاعها وتنظيمها؟",
  ),
  "request": TechnicalCodeScenario(
    code: "GET /api/cards HTTP/1.1",
    question: "ماذا تُسمّى الرسالة التي يرسلها العميل إلى الخادم؟",
  ),
  "endpoint": TechnicalCodeScenario(
    code: "GET /api/orders/42",
    question: "ما اسم عنوان الخدمة الذي يتلقى طلبًا محددًا؟",
  ),
  "response": TechnicalCodeScenario(
    code: "HTTP/1.1 200 OK\nContent-Type: application/json",
    question: "ماذا يسمى الرد الذي يرجعه الخادم بعد معالجة طلب؟",
  ),
  "json": TechnicalCodeScenario(
    code: "{\"success\":true,\"count\":3}",
    question: "ما صيغة البيانات النصية التي تستخدم مفاتيح وقيمًا مثل المثال؟",
  ),
  "print": TechnicalCodeScenario(
    code: "print('Welcome');",
    question: "ما التعليمة التي تعرض نصًا في مخرجات البرنامج؟",
  ),
  "extra_widget": TechnicalCodeScenario(
    code: "Text('Hello', style: TextStyle(fontSize: 18))",
    question: "ما اسم المكوّن الذي يكوّن أجزاء واجهة Flutter؟",
  ),
  "extra_state": TechnicalCodeScenario(
    code: "setState(() {\n  counter++;\n});",
    question: "ما المفهوم الذي يصف البيانات المتغيرة المؤثرة على الواجهة؟",
  ),
  "extra_stateful_widget": TechnicalCodeScenario(
    code: "class CounterPage extends StatefulWidget {\n  const CounterPage({super.key});\n}",
    question: "ما نوع مكوّن Flutter الذي يمكنه الاحتفاظ بحالة متغيرة؟",
  ),
  "extra_stateless_widget": TechnicalCodeScenario(
    code: "class Logo extends StatelessWidget {\n  const Logo({super.key});\n}",
    question: "ما نوع مكوّن Flutter الذي لا يملك حالة داخلية قابلة للتغيير؟",
  ),
  "extra_future": TechnicalCodeScenario(
    code: "Future<String> loadName() async => 'Ali';",
    question: "ما النوع الذي يمثل نتيجة عملية غير متزامنة ستُتاح لاحقًا؟",
  ),
  "extra_map": TechnicalCodeScenario(
    code: "final item = {'id': 7, 'name': 'Pen'};",
    question: "ما بنية البيانات التي تربط كل مفتاح بقيمة؟",
  ),
  "extra_set": TechnicalCodeScenario(
    code: "final unique = <int>{1, 2, 2, 3};",
    question: "ما المجموعة التي لا تحتفظ بالقيم المكررة؟",
  ),
  "extra_class": TechnicalCodeScenario(
    code: "class Product {\n  final String name;\n  Product(this.name);\n}",
    question: "ما القالب البرمجي المستخدم لتعريف بيانات الكائن وسلوكه؟",
  ),
  "extra_constructor": TechnicalCodeScenario(
    code: "class Product {\n  Product(this.name);\n  final String name;\n}",
    question: "ما اسم الدالة الخاصة التي تُستدعى عند إنشاء كائن؟",
  ),
  "extra_sql_query": TechnicalCodeScenario(
    code: "SELECT name FROM products WHERE stock > 0;",
    question: "ما اسم التعليمة التي تطلب نتائج محددة من قاعدة البيانات؟",
  ),
  "extra_sql_table": TechnicalCodeScenario(
    code: "CREATE TABLE cards (id INT, word TEXT);",
    question: "ما بنية قاعدة البيانات التي تنظّم البيانات في صفوف وأعمدة؟",
  ),
  "extra_primary_key": TechnicalCodeScenario(
    code: "CREATE TABLE cards (id INT PRIMARY KEY, word TEXT);",
    question: "ما القيد الذي يميّز كل سجل بمعرّف فريد؟",
  ),
  "extra_foreign_key": TechnicalCodeScenario(
    code: "CREATE TABLE orders (\n customer_id INT REFERENCES customers(id)\n);",
    question: "ما القيد المستخدم لربط سجل في جدول بسجل في جدول آخر؟",
  ),
  "extra_transaction": TechnicalCodeScenario(
    code: "BEGIN;\nUPDATE accounts SET balance = balance - 10;\nCOMMIT;",
    question: "ما الوحدة التي تجمع عمليات قاعدة البيانات لتنجح أو تفشل معًا؟",
  ),
  "extra_html": TechnicalCodeScenario(
    code: "<main><h1>Welcome</h1></main>",
    question: "ما لغة الترميز المستخدمة لبناء هيكل صفحة ويب؟",
  ),
  "extra_css": TechnicalCodeScenario(
    code: "h1 { color: navy; margin: 12px; }",
    question: "ما لغة الأنماط المستخدمة للتحكم في مظهر صفحة الويب؟",
  ),
  "extra_javascript": TechnicalCodeScenario(
    code: "document.querySelector('#save').click();",
    question: "ما لغة البرمجة الشائعة لإضافة سلوك تفاعلي إلى صفحات الويب؟",
  ),
  "extra_dom": TechnicalCodeScenario(
    code: "document.getElementById('heading').textContent = 'Hi';",
    question: "ما تمثيل عناصر صفحة الويب الذي يسمح بتعديلها برمجيًا؟",
  ),
  "extra_http_get": TechnicalCodeScenario(
    code: "GET /products HTTP/1.1",
    question: "ما طريقة HTTP المستخدمة عادةً لقراءة مورد؟",
  ),
  "extra_http_post": TechnicalCodeScenario(
    code: "POST /orders HTTP/1.1\nContent-Type: application/json",
    question: "ما طريقة HTTP المستخدمة غالبًا لإنشاء مورد جديد؟",
  ),
  "extra_http_put": TechnicalCodeScenario(
    code: "PUT /items/12 HTTP/1.1",
    question: "ما طريقة HTTP المستخدمة عادةً لاستبدال تمثيل مورد؟",
  ),
  "extra_http_patch": TechnicalCodeScenario(
    code: "PATCH /items/12 HTTP/1.1\n{\"stock\": 5}",
    question: "ما طريقة HTTP المستخدمة لتعديل جزء من مورد؟",
  ),
  "extra_http_delete": TechnicalCodeScenario(
    code: "DELETE /items/12 HTTP/1.1",
    question: "ما طريقة HTTP المستخدمة لطلب حذف مورد؟",
  ),
  "extra_http_header": TechnicalCodeScenario(
    code: "Authorization: Bearer <TOKEN>\nAccept: application/json",
    question: "ما اسم حقول البيانات الوصفية التي ترافق طلب HTTP؟",
  ),
  "extra_validation": TechnicalCodeScenario(
    code: "if (email.isEmpty) {\n  throw ArgumentError('Required');\n}",
    question: "ما العملية المستخدمة للتأكد من أن المدخلات تفي بالشروط؟",
  ),
  "extra_environment_variable": TechnicalCodeScenario(
    code: "API_URL=https://api.example.org",
    question: "ما الوسيلة المستخدمة لتمرير إعدادات تشغيل إلى البرنامج من البيئة؟",
  ),
  "extra_container": TechnicalCodeScenario(
    code: "docker run --rm -p 8080:80 nginx",
    question: "ما البيئة المعزولة نسبيًا لتشغيل برنامج مع اعتماده؟",
  ),
  "extra_continuous_integration": TechnicalCodeScenario(
    code: "on: [push]\njobs:\n  test:\n    runs-on: ubuntu-latest",
    question: "ما ممارسة التشغيل الآلي لفحوص الكود مع كل تغيير؟",
  ),
  "extra_rollback": TechnicalCodeScenario(
    code: "git revert abc1234",
    question: "ما المصطلح الذي يصف الرجوع عن تعديل غير مناسب؟",
  ),
  "extra_api_token": TechnicalCodeScenario(
    code: "Authorization: Bearer example-token",
    question: "ما بيانات الاعتماد التي تُرسل للخدمة للتعرّف على صلاحية الوصول؟",
  ),
  "extra_web_component": TechnicalCodeScenario(
    code: "customElements.define('user-card', UserCard);",
    question: "ما مكوّن واجهة ويب قابل لإعادة الاستخدام وفق معايير المتصفح؟",
  ),
  "extra_ui_event": TechnicalCodeScenario(
    code: "button.addEventListener('click', saveForm);",
    question: "ما اسم وقوع تفاعل مثل النقر الذي تستجيب له الواجهة؟",
  ),
  "extra_hashing": TechnicalCodeScenario(
    code: "final digest = sha256.convert(utf8.encode('data'));",
    question: "ما العملية التي تحوّل البيانات إلى بصمة ثابتة الطول غالبًا؟",
  ),
  "extra_rate_limit": TechnicalCodeScenario(
    code: "HTTP/1.1 429 Too Many Requests",
    question: "ما السياسة التي تحدد عدد الطلبات المسموح بها في فترة زمنية؟",
  ),
  "extra_pagination": TechnicalCodeScenario(
    code: "GET /products?page=2&limit=20",
    question: "ما طريقة تقسيم نتائج API إلى صفحات متتابعة؟",
  ),
  "extra_webhook": TechnicalCodeScenario(
    code: "POST /events/order-updated HTTP/1.1",
    question: "ما نمط إشعار الأنظمة الخارجية تلقائيًا عند وقوع حدث؟",
  ),
  "extra_payload": TechnicalCodeScenario(
    code: "{\"order_id\": 123, \"status\": \"shipped\"}",
    question: "ما اسم البيانات الأساسية المحمولة داخل رسالة حدث؟",
  ),
};

/// Avoid giving away the answer in a scenario when an English term happens
/// to be mentioned in the lesson's Arabic teaching note.
String maskAnswerTerm(String source, String term) {
  if (term.trim().isEmpty) return source;
  final escaped = RegExp.escape(term.trim());
  return source.replaceAll(RegExp(escaped, caseSensitive: false), '_____');
}

List<T> buildDifficultyQuizCards<T>({
  required Iterable<T> catalog,
  required String Function(T card) cardId,
  required QuizDifficulty difficulty,
  required int completedAttempts,
  int questionsPerQuiz = 6,
}) {
  if (questionsPerQuiz <= 0) return <T>[];
  final ids = <String>{};
  final pool = <T>[];
  for (final card in catalog) {
    final id = cardId(card);
    if (id.isEmpty || !ids.add(id)) {
      continue;
    }
    if (difficulty == QuizDifficulty.advanced &&
        !advancedCodeScenarios.containsKey(id)) {
      continue;
    }
    pool.add(card);
  }
  if (pool.isEmpty) return <T>[];
  final count = questionsPerQuiz < pool.length
      ? questionsPerQuiz : pool.length;
  final tries = completedAttempts < 0 ? 0 : completedAttempts;
  final start = ((tries % pool.length) * (count % pool.length)) % pool.length;
  return List<T>.unmodifiable([
    for (var i = 0; i < count; i++) pool[(start + i) % pool.length],
  ]);
}
