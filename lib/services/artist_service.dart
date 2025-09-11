//The Gearsh App - Artist Service

import 'dart:convert';
import '../models/artist.dart';
import '../core/utils/airtable_api.dart';

class ArtistService {
  final String table = 'Artists';

  Future<List<Artist>> fetchArtists({String? search, String? category}) async {
    try {
      final filterFormula =
          _buildFilterFormula(search: search, category: category);
      final response = await AirtableApi.getRecords(
        tableName: table,
        filterFormula: filterFormula,
      );

      if (response.statusCode == 200) {
        final records = jsonDecode(response.body)['records'] as List;
        return records.map((record) => Artist.fromJson(record)).toList();
      } else {
        throw Exception('Failed to load artists: \${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  String? _buildFilterFormula({String? search, String? category}) {
    List<String> filters = [];

    if (search != null && search.isNotEmpty) {
      // ignore: unused_local_variable
      final s = search.replaceAll("'", "\\'");
      filters.add("OR(FIND('\$s', {name}), FIND('\$s', {genre}))");
    }

    if (category != null && category.isNotEmpty) {
      // ignore: unused_local_variable
      final c = category.replaceAll("'", "\\'");
      filters.add("{category} = '\$c'");
    }

    if (filters.isEmpty) return null;
    return filters.length > 1 ? "AND(\${filters.join(', ')})" : filters.first;
  }
}
