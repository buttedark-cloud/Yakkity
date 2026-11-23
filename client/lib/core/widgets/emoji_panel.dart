import 'package:flutter/material.dart';

const _emojis = [
  '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇', '🙂', '😉',
  '😍', '🥰', '😘', '😋', '😜', '🤪', '😎', '🤩', '🥳', '😏', '😒', '😔',
  '😢', '😭', '😤', '😡', '🤯', '😱', '😳', '🥺', '🤔', '🤗', '🤭', '😴',
  '🤤', '😷', '🤒', '🥵', '🥶', '🙄', '😬', '🫠', '👍', '👎', '👏', '🙌',
  '🙏', '💪', '🤝', '✌️', '🤞', '👌', '🤙', '👋', '🫶', '❤️', '🧡', '💛',
  '💚', '💙', '💜', '🖤', '🤍', '💔', '💖', '💯', '🔥', '✨', '⭐', '🌟',
  '🎉', '🎂', '🎁', '☕', '🍕', '🍔', '🍰', '🍎', '🌹', '🌸', '☀️', '🌈',
  '⛰️', '🌴', '🚀', '✈️', '🎧', '🎮', '📸', '💻', '📱', '🏠', '🐶', '🐱',
];

/// Сетка смайликов. Нажатие вызывает [onSelected] с выбранным смайликом.
class EmojiPanel extends StatelessWidget {
  const EmojiPanel({super.key, required this.onSelected, this.height = 240});

  final ValueChanged<String> onSelected;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 46,
          mainAxisExtent: 46,
        ),
        itemCount: _emojis.length,
        itemBuilder: (context, i) => InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onSelected(_emojis[i]),
          child: Center(
            child: Text(_emojis[i], style: const TextStyle(fontSize: 26)),
          ),
        ),
      ),
    );
  }
}

/// Вставляет [text] в позицию курсора (или заменяет выделенное).
/// Если задан [maxRunes] и результат длиннее, ничего не делает.
void insertTextAtCursor(TextEditingController controller, String text,
    {int? maxRunes}) {
  final value = controller.text;
  final sel = controller.selection;
  final start = sel.isValid && sel.start >= 0 ? sel.start : value.length;
  final end = sel.isValid && sel.end >= 0 ? sel.end : value.length;
  final newText = value.replaceRange(start, end, text);
  if (maxRunes != null && newText.runes.length > maxRunes) return;
  controller.value = TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: start + text.length),
  );
}
