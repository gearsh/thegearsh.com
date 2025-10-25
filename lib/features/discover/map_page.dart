import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gearsh_app/models/artist.dart';
import 'package:gearsh_app/providers/artist_provider.dart';

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
  }

  Future<void> _loadArtists() async {
    final artists = await ref.read(artistListProvider.future);
    _updateMarkers(artists);
  }

  void _updateMarkers(List<Artist> artists) {
    final markers = <String, Marker>{};
    for (final artist in artists) {
      if (artist.location != null) {
        // TODO: Replace with actual geocoding logic
        final position = _getLatLngFromLocation(artist.location!);
        if (position != null) {
          final marker = Marker(
            markerId: MarkerId(artist.id),
            position: position,
            infoWindow: InfoWindow(
              title: artist.name,
              snippet: artist.category,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
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

  LatLng? _getLatLngFromLocation(String location) {
    // This is a placeholder. You'll need to implement a geocoding service
    // to convert addresses into latitude and longitude.
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
        },
        markers: Set<Marker>.of(_markers.values),
      ),
    );
  }
}
