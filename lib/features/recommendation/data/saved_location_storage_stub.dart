class SavedLocationStorage {
  final Map<String, String> _memory = <String, String>{};

  Future<String?> read(String key) async => _memory[key];

  Future<void> write(String key, String value) async {
    _memory[key] = value;
  }
}
