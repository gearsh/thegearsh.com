import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gearsh_app/core/contracts/i_content_repository.dart';
import 'package:gearsh_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Content Engine client — loads JSON copy & theme from `/api/content`.
class ContentService implements IContentRepository {
  static const _cacheKey = 'gearsh_content_cache_v1';

  ContentBundle _bundle = const ContentBundle(copy: {}, theme: {});
  final ApiService _api;
  final SharedPreferences _prefs;

  ContentService(this._api, this._prefs);

  @override
  int get version => _bundle.version;

  @override
  Map<String, dynamic> get themeTokens => _bundle.theme;

  @override
  Future<ContentBundle> fetchContent({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _prefs.getString(_cacheKey);
      if (cached != null) {
        try {
          final json = jsonDecode(cached) as Map<String, dynamic>;
          _bundle = ContentBundle(
            copy: Map<String, dynamic>.from(json['copy'] as Map? ?? {}),
            theme: Map<String, dynamic>.from(json['theme'] as Map? ?? {}),
            version: json['version'] as int? ?? 1,
          );
        } catch (e) {
          debugPrint('[ContentService] cache parse failed: $e');
        }
      }
    }

    final response = await _api.get('/content');
    final payload = response.getData<Map<String, dynamic>>();
    if (payload != null) {
      _bundle = ContentBundle(
        copy: Map<String, dynamic>.from(payload['copy'] as Map? ?? {}),
        theme: Map<String, dynamic>.from(payload['theme'] as Map? ?? {}),
        version: payload['version'] as int? ?? 1,
      );
      await _prefs.setString(_cacheKey, jsonEncode({
        'copy': _bundle.copy,
        'theme': _bundle.theme,
        'version': _bundle.version,
      }));
    }

    return _bundle;
  }

  @override
  String copy(String path, {String fallback = ''}) {
    final parts = path.split('.');
    dynamic node = _bundle.copy;
    for (final part in parts) {
      if (node is! Map) return fallback;
      node = node[part];
      if (node == null) return fallback;
    }
    return node is String ? node : fallback;
  }
}
