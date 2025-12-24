// filepath: lib/features/signups/artists_list_page.dart
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:gearsh_app/widgets/custom_app_bar.dart';
import 'package:go_router/go_router.dart';

class ArtistsListPage extends ConsumerWidget {
  const ArtistsListPage({super.key});

  Future<List<Map<String, dynamic>>> fetchArtists() async {
    // Use the current origin so the same Pages/Functions host works for web.
    final base = Uri.base.origin;
    final uri = Uri.parse('$base/api/get_signups');

    final resp = await http.get(uri, headers: { 'Accept': 'application/json' });
    if (resp.statusCode != 200) {
      throw Exception('Failed to load artists (${resp.statusCode})');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (body['success'] == true) {
      final list = List<Map<String, dynamic>>.from(body['data'] as List);
      return list;
    }
    throw Exception(body['error'] ?? 'Unknown error');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const CustomAppBar(title: 'Artists'),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchArtists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final artists = snapshot.data ?? [];
          if (artists.isEmpty) {
            return Center(child: Text('No artists found.', style: theme.textTheme.bodyLarge));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: artists.length,
            separatorBuilder: (_, __) => const Divider(height: 8),
            itemBuilder: (context, index) {
              final a = artists[index];
              final first = (a['first_name'] ?? '').toString();
              final sur = (a['surname'] ?? '').toString();
              final username = (a['user_name'] ?? '').toString();
              final email = (a['email'] ?? '').toString();
              final title = (first.isNotEmpty || sur.isNotEmpty) ? '$first $sur'.trim() : username;

              String? avatarUrl;
              // If your signups table contains an image/profile URL field, adjust key name here
              if (a.containsKey('profile_picture_url')) {
                avatarUrl = a['profile_picture_url'] as String?;
              }

              return ListTile(
                leading: avatarUrl != null && avatarUrl.isNotEmpty
                    ? CircleAvatar(
                        backgroundImage: CachedNetworkImageProvider(avatarUrl),
                      )
                    : CircleAvatar(child: Text(title.isNotEmpty ? title[0].toUpperCase() : '?')),
                title: Text(title, style: theme.textTheme.titleLarge),
                subtitle: Text(email.isNotEmpty ? email : username, style: theme.textTheme.bodyMedium),
                onTap: () {
                  final id = a['id']?.toString();
                  if (id != null && id.isNotEmpty) {
                    GoRouter.of(context).go('/profile/$id');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
