import 'package:flutter/services.dart';

/// Helper for clipboard operations.
class ClipboardUtils {
  ClipboardUtils._();

  /// Check if the clipboard contains text that looks translatable.
  ///
  /// Returns the clipboard text if it is non-empty and at least 2 characters
  /// long, otherwise returns null.
  static Future<String?> getTranslatableContent() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.length >= 2) {
      return text;
    }
    return null;
  }

  /// Copy [text] to the system clipboard.
  static Future<void> copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
