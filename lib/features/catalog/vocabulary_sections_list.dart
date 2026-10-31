import 'package:flutter/material.dart';

import 'vocabulary_sections.dart';

/// Only six top-level cards are visible until the learner opens a section.
/// Internal lessons retain their own completion state and existing navigation.
class VocabularySectionsList extends StatelessWidget {
  const VocabularySectionsList({
    super.key,
    required this.sections,
    required this.titleOf,
    required this.levelOf,
    required this.learnedOf,
    required this.totalOf,
    required this.onOpenLesson,
    this.expandSearchResults = false,
  });

  final List<VocabularySectionSelection> sections;
  final String Function(int index) titleOf;
  final String Function(int index) levelOf;
  final int Function(int index) learnedOf;
  final int Function(int index) totalOf;
  final ValueChanged<int> onOpenLesson;
  final bool expandSearchResults;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF101D32);
    const purple = Color(0xFF6857CE);
    const muted = Color(0xFF667085);
    const tints = [
      Color(0xFFEAE5FF),
      Color(0xFFFFE7DC),
      Color(0xFFDDEEF3),
      Color(0xFFE8F2E3),
      Color(0xFFFFEEDA),
      Color(0xFFE8EAFB),
    ];
    const icons = [
      Icons.computer_rounded,
      Icons.code_rounded,
      Icons.web_rounded,
      Icons.security_rounded,
      Icons.shopping_bag_outlined,
      Icons.psychology_rounded,
    ];

    return Column(
      key: const Key('vocabulary_section_list'),
      children: [
        for (var groupIndex = 0; groupIndex < sections.length; groupIndex++)
          Padding(
            padding: const EdgeInsets.only(bottom: 13),
            child: Material(
              key: Key('section_${sections[groupIndex].section.id}'),
              color: Colors.white,
              borderRadius: BorderRadius.circular(23),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                key: Key('section_expand_${sections[groupIndex].section.id}_${expandSearchResults ? "search" : "all"}'),
                initiallyExpanded: expandSearchResults,
                tilePadding: const EdgeInsets.fromLTRB(17, 15, 17, 13),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 15),
                shape: const Border(),
                collapsedShape: const Border(),
                leading: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: tints[groupIndex % tints.length],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icons[groupIndex % icons.length],
                    size: 27, color: navy),
                ),
                title: Text(
                  sections[groupIndex].section.title,
                  style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w900, color: navy),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Builder(builder: (context) {
                    final count = sections[groupIndex].lessonIndices.length;
                    final total = sections[groupIndex].lessonIndices.fold<int>(
                      0, (sum, i) => sum + totalOf(i),
                    );
                    final learned = sections[groupIndex].lessonIndices.fold<int>(
                      0, (sum, i) => sum + learnedOf(i),
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sections[groupIndex].section.description,
                          style: const TextStyle(
                            fontSize: 12, color: muted, height: 1.5)),
                        const SizedBox(height: 6),
                        Text('$count دروس • $learned من $total كلمة',
                          key: Key('section_progress_${sections[groupIndex].section.id}'),
                          style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: purple)),
                        const SizedBox(height: 9),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: LinearProgressIndicator(
                            value: total == 0 ? 0 : learned / total,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFECEEF3),
                            color: const Color(0xFFFF653B),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                children: [
                  const Divider(height: 19, color: Color(0xFFEEEAF4)),
                  for (final lessonIndex in sections[groupIndex].lessonIndices)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Material(
                        color: const Color(0xFFF8F7FB),
                        borderRadius: BorderRadius.circular(15),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: Key('lesson_$lessonIndex'),
                          onTap: () => onOpenLesson(lessonIndex),
                          child: Padding(
                            padding: const EdgeInsets.all(13),
                            child: Row(
                              children: [
                                const Icon(Icons.menu_book_outlined,
                                  color: purple, size: 22),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(titleOf(lessonIndex),
                                        style: const TextStyle(
                                          color: navy, fontSize: 15,
                                          fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 5),
                                      Text(
                                        'المستوى: ${levelOf(lessonIndex)} • '
                                        '${learnedOf(lessonIndex)} من '
                                        '${totalOf(lessonIndex)} كلمات',
                                        style: const TextStyle(
                                          color: muted, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                if (totalOf(lessonIndex) > 0 &&
                                    learnedOf(lessonIndex) ==
                                        totalOf(lessonIndex))
                                  const Icon(Icons.check_circle_rounded,
                                    color: Color(0xFF21865B), size: 21)
                                else
                                  const Icon(Icons.arrow_back_ios_new_rounded,
                                    color: purple, size: 15),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
