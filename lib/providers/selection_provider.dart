import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the currently selected artist id for UI interactions (map centering, etc.)
class SelectionNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void selectArtist(String? artistId) {
    state = artistId;
  }

  void clearSelection() {
    state = null;
  }
}

final selectedArtistIdProvider = NotifierProvider<SelectionNotifier, String?>(SelectionNotifier.new);
