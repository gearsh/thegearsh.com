import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/data/gearsh_artists.dart';

class CategoryArtistsPage extends StatelessWidget {
  final String category;

  const CategoryArtistsPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final artists = getArtistsByCategory(category);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              GoRouter.of(context).pop();
            } else {
              GoRouter.of(context).go('/home');
            }
          },
        ),
        title: Text('$category Artists'),
        backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.95),
      ),
      body: SafeArea(
        child: artists.isEmpty
            ? Center(
                child: Text('No artists found for $category'),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.70,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: artists.length,
                itemBuilder: (context, index) {
                  final artist = artists[index];
                  return GestureDetector(
                    onTap: () => GoRouter.of(context).go('/artist/${artist.id}'),
                    child: Card(
                      color: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Image.asset(
                              artist.image,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[800],
                                child: const Center(
                                  child: Icon(Icons.person, size: 48, color: Colors.white54),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      artist.name,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Flexible(
                                    child: Text(
                                      artist.category,
                                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Flexible(
                                    child: Text(
                                      'R${artist.bookingFee}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// Top-level builder used by routes to avoid direct class resolution issues
Widget categoryArtistsPageBuilder(String category) => CategoryArtistsPage(category: category);

