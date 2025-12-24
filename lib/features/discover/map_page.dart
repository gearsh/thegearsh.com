import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gearsh_app/models/artist.dart';
import 'package:gearsh_app/providers/artist_provider.dart';
import 'package:gearsh_app/providers/selection_provider.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  GoogleMapController? _mapController;
  final Map<String, Marker> _markers = {};
  final LatLng _initialPosition = const LatLng(37.7749, -122.4194); // San Francisco

  @override
  void initState() {
    super.initState();
    _loadArtists();

    // Listen for selection changes to center map
    ref.listen<String?>(selectedArtistIdProvider, (previous, next) async {
      if (next != null) {
        final artist = await ref.read(artistByIdProvider(next).future);
        if (artist != null && artist.location != null) {
          final latLng = await _getLatLngFromLocation(artist.location!);
          if (latLng != null) {
            _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));
          }
        }
      }
    });
  }

  Future<void> _loadArtists() async {
    final artists = await ref.read(artistListProvider.future);
    await _updateMarkers(artists);
  }

  Future<void> _updateMarkers(List<Artist> artists) async {
    final markers = <String, Marker>{};
    for (final artist in artists) {
      if (artist.location != null) {
        final position = await _getLatLngFromLocation(artist.location!);
        if (position != null) {
          final marker = Marker(
            markerId: MarkerId(artist.id),
            position: position,
            infoWindow: InfoWindow(
              title: artist.name,
              snippet: artist.category,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            onTap: () {
              // update selected artist when marker tapped
              ref.read(selectedArtistIdProvider.notifier).selectArtist(artist.id);
            },
          );
          markers[artist.id] = marker;
        }
      }
    }
    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });
  }

  Future<LatLng?> _getLatLngFromLocation(String location) async {
    try {
      final results = await geocoding.locationFromAddress(location);
      if (results.isNotEmpty) {
        final first = results.first;
        return LatLng(first.latitude, first.longitude);
      }
    } catch (e) {
      // ignore errors and fallback to placeholder table
    }

    // Fallback locations for known mock strings
    if (location.toLowerCase().contains('pretoria')) return const LatLng(-25.7479, 28.2293);
    if (location.toLowerCase().contains('durban')) return const LatLng(-29.8587, 31.0218);
    if (location.toLowerCase().contains('johannesburg')) return const LatLng(-26.2041, 28.0473);
    if (location == 'New York, NY') return const LatLng(40.7128, -74.0060);
    if (location == 'Los Angeles, CA') return const LatLng(34.0522, -118.2437);
    if (location == 'San Francisco, CA') return const LatLng(37.7749, -122.4194);
    if (location == 'Compton, CA') return const LatLng(33.8958, -118.2201);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Artists'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 12,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
          _mapController?.animateCamera(CameraUpdate.newLatLng(_initialPosition));
        },
        markers: Set<Marker>.of(_markers.values),
      ),
    );
  }
}
