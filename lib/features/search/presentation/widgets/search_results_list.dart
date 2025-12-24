import 'package:flutter/material.dart';
import 'package:gearsh_app/models/search_models.dart';
import 'package:go_router/go_router.dart';

class SearchResultsList extends StatelessWidget {
  final List<SearchResult> results;

  const SearchResultsList({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        final artist = result.artist;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(artist.profilePictureUrl),
          ),
          title: Text(artist.name),
          subtitle: Text(artist.category ?? 'No category'),
          trailing: Text('Score: ${result.score.toStringAsFixed(2)}'),
          onTap: () => context.go('/profile/${artist.id}'),
        );
      },
    );
  }
}

