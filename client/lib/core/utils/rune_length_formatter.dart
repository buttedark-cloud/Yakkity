import 'package:flutter/services.dart';

/// Ограничивает длину по настоящим символам, а не по UTF-16 единицам:
/// смайлик считается за один символ, как и на сервере.
class RuneLengthFormatter extends TextInputFormatter {
  const RuneLengthFormatter(this.max);
  final int max;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.runes.length <= max) return newValue;
    final cut = String.fromCharCodes(newValue.text.runes.take(max));
    return TextEditingValue(
      text: cut,
      selection: TextSelection.collapsed(offset: cut.length),
    );
  }
}
