import 'package:flutter/material.dart';

/// A snapshot of one missed vocabulary question in the current quiz session.
/// It intentionally does not modify saved flashcard mastery or review dates.
class QuizMistake {
  const QuizMistake({
    required this.word,
    required this.pronunciation,
    required this.selectedTranslation,
    required this.correctTranslation,
    required this.example,
    required this.explanation,
    required this.projectUse,
  });

  final String word;
  final String pronunciation;
  final String selectedTranslation;
  final String correctTranslation;
  final String example;
  final String explanation;
  final String projectUse;
}

class QuizMistakesReviewPage extends StatelessWidget {
  const QuizMistakesReviewPage({
    super.key,
    required this.mistakes,
  });

  final List<QuizMistake> mistakes;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF101D32);
    const orange = Color(0xFFFF653B);
    const green = Color(0xFF21865B);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مراجعة كلمات الاختبار'),
        ),
        body: SafeArea(
          child: mistakes.isEmpty
              ? const Center(child: Text('لم تخطئ في أي كلمة!'))
              : ListView(
                  key: const Key('quiz_mistakes_list'),
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(19),
                      decoration: BoxDecoration(
                        color: navy,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(children: [
                            Icon(Icons.school_outlined, color: Colors.white),
                            SizedBox(width: 10),
                            Text('راجع لتفهم، لا للحفظ فقط',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800)),
                          ]),
                          const SizedBox(height: 11),
                          Text(
                            'لديك ${mistakes.length} كلمات للمراجعة من آخر اختبار.',
                            style: const TextStyle(
                              color: Colors.white, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (var i = 0; i < mistakes.length; i++) ...[
                      Container(
                        key: Key('quiz_mistake_$i'),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(21),
                          border: Border.all(
                            color: const Color(0xFFE6E6EF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الكلمة ${i + 1} من ${mistakes.length}',
                              style: const TextStyle(
                                color: Color(0xFF667085),
                                fontSize: 13,
                                fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              mistakes[i].word,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                color: navy,
                                fontSize: 25,
                                fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mistakes[i].pronunciation,
                              style: const TextStyle(
                                color: Color(0xFF667085)),
                            ),
                            const SizedBox(height: 15),
                            Text('إجابتك: ${mistakes[i].selectedTranslation}',
                              style: const TextStyle(
                                color: Color(0xFFB94824), height: 1.5)),
                            const SizedBox(height: 7),
                            Text('الصحيح: ${mistakes[i].correctTranslation}',
                              style: const TextStyle(
                                color: green,
                                fontWeight: FontWeight.w800,
                                height: 1.5)),
                            const SizedBox(height: 15),
                            const Text('لماذا؟',
                              style: TextStyle(
                                color: navy,
                                fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text(mistakes[i].explanation,
                              style: const TextStyle(
                                color: navy, height: 1.65)),
                            if (mistakes[i].projectUse.isNotEmpty) ...[
                              const SizedBox(height: 13),
                              const Text('من واقع المشاريع',
                                style: TextStyle(
                                  color: navy,
                                  fontWeight: FontWeight.w800)),
                              const SizedBox(height: 5),
                              Text(mistakes[i].projectUse,
                                style: const TextStyle(
                                  color: navy, height: 1.6)),
                            ],
                            if (mistakes[i].example.isNotEmpty) ...[
                              const SizedBox(height: 13),
                              const Text('مثال',
                                style: TextStyle(
                                  color: orange,
                                  fontWeight: FontWeight.w800)),
                              const SizedBox(height: 5),
                              SelectableText(mistakes[i].example,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  color: navy, height: 1.6)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 13),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
