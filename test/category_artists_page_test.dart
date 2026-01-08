import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gearsh_app/features/discover/category_artists_page.dart';
import 'package:gearsh_app/data/gearsh_artists.dart';

void main() {
  group('CategoryArtistsPage', () {
    testWidgets('displays category name in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryArtistsPage(category: 'DJ'),
        ),
      );

      expect(find.text('DJ Artists'), findsOneWidget);
    });

    testWidgets('shows empty message when no artists found', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryArtistsPage(category: 'NonExistentCategory'),
        ),
      );

      expect(find.text('No artists found for NonExistentCategory'), findsOneWidget);
    });

    testWidgets('displays artists grid when artists exist', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryArtistsPage(category: 'Amapiano'),
        ),
      );

      // Should find GridView for artists
      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('uniqueArtists helper', () {
    test('removes duplicate artists by ID', () {
      final unique = uniqueArtists();
      final ids = unique.map((a) => a.id).toSet();

      // All IDs should be unique
      expect(ids.length, equals(unique.length));
    });

    test('getUniqueFeaturedArtists returns verified high-rated artists', () {
      final featured = getUniqueFeaturedArtists(limit: 10);

      for (final artist in featured) {
        expect(artist.isVerified, isTrue);
        expect(artist.rating, greaterThanOrEqualTo(4.4));
      }
      expect(featured.length, lessThanOrEqualTo(10));
    });

    test('getUniqueTrendingArtists returns available artists', () {
      final trending = getUniqueTrendingArtists(limit: 15);

      for (final artist in trending) {
        expect(artist.isAvailable, isTrue);
        expect(artist.rating, greaterThanOrEqualTo(4.0));
      }
      expect(trending.length, lessThanOrEqualTo(15));
    });

    test('getArtistsByCategory returns artists matching category', () {
      final djArtists = getArtistsByCategory('DJ');

      for (final artist in djArtists) {
        final matchesCategory = artist.category.toLowerCase() == 'dj' ||
            artist.subcategories.any((s) => s.toLowerCase() == 'dj');
        expect(matchesCategory, isTrue);
      }
    });
  });
}

