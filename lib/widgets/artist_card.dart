import 'package:flutter/material.dart';
import '../../models/artist.dart';

class ArtistCard extends StatelessWidget {
  final Artist artist;
  final VoidCallback onTap;

  const ArtistCard({super.key, required this.artist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple,
          child: Text(artist.name[0], style: const TextStyle(color: Colors.white)),
        ),
        title: Text(artist.name, style: const TextStyle(color: Colors.white)),
        subtitle: Text(artist.genre, style: const TextStyle(color: Colors.white70)),
        trailing: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          child: const Text('Book'),
        ),
      ),
    );
  }
}
