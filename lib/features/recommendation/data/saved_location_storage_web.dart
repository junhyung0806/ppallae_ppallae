// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

class SavedLocationStorage {
  Future<String?> read(String key) async => html.window.localStorage[key];

  Future<void> write(String key, String value) async {
    html.window.localStorage[key] = value;
  }
}
