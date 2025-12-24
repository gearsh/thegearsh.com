import 'package:gearsh_app/models/artist.dart';

class SearchResult {
  final Artist artist;
  final double score;
  final Set<String> matchedFields;

  SearchResult({
    required this.artist,
    required this.score,
    this.matchedFields = const {},
  });
}

