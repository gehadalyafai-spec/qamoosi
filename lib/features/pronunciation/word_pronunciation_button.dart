import 'package:flutter/material.dart';

import 'word_speaker.dart';

/// A listening control that does not answer a quiz or flip its parent card.
/// The parent page supplies one shared speaker for all its visible words.
class WordPronunciationButton extends StatefulWidget {
  const WordPronunciationButton({
    super.key,
    required this.word,
    required this.speaker,
    this.slowly = false,
    this.compact = false,
  });

  final String word;
  final WordSpeaker speaker;
  final bool slowly;
  final bool compact;

  @override
  State<WordPronunciationButton> createState() =>
      _WordPronunciationButtonState();
}

class _WordPronunciationButtonState extends State<WordPronunciationButton> {
  bool _speaking = false;

  Future<void> _play() async {
    if (_speaking || widget.word.trim().isEmpty) return;
    setState(() => _speaking = true);
    try {
      await widget.speaker.speak(widget.word, slowly: widget.slowly);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text(
              'تعذّر نطق الكلمة. تحقّق من توفر صوت إنجليزي في إعدادات النطق بالجهاز.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.slowly ? 'استمع ببطء' : 'استمع للنطق';
    if (widget.compact) {
      return IconButton(
        tooltip: '$label: ${widget.word}',
        onPressed: _speaking ? null : _play,
        icon: Icon(
          widget.slowly
              ? Icons.slow_motion_video_rounded
              : Icons.volume_up_rounded,
          color: const Color(0xFF6554C0),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: _speaking ? null : _play,
      icon: Icon(widget.slowly
          ? Icons.slow_motion_video_rounded
          : Icons.volume_up_rounded),
      label: Text(widget.slowly ? 'ببطء' : 'استمع'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF6554C0),
        side: const BorderSide(color: Color(0xFFD9D1FF)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
