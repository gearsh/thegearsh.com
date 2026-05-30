/// Content Engine contract — JSON-managed copy and theme tokens.
abstract class IContentRepository {
  Future<ContentBundle> fetchContent({bool forceRefresh = false});
  String copy(String path, {String fallback});
  Map<String, dynamic> get themeTokens;
  int get version;
}

class ContentBundle {
  final Map<String, dynamic> copy;
  final Map<String, dynamic> theme;
  final int version;

  const ContentBundle({
    required this.copy,
    required this.theme,
    this.version = 1,
  });
}
