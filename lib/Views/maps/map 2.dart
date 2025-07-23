import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:therapylink/utils/colors.dart';

import 'google_places_service.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;

  LatLng? _currentPosition;

  final Set<Marker> _markers = {};
  final Map<String, MarkerId> _markerIds = {};

  List<Place> _clinics = [];
  bool _loadingLocation = true;
  bool _loadingClinics = false;

  Place? _selectedClinic;

  final GooglePlacesService _placesService = GooglePlacesService(
    apiKey: 'AIzaSyBRGgGd3AhtZrH1ZWy3i80oA3XNvUf3JHE',
  );

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await _ensureLocationEnabled();
    await _determinePosition();
    await _mergeFavsIntoCurrentList();
  }

  Future<void> _mergeFavsIntoCurrentList() async {
    final favIds = await _placesService.loadFavoriteIds();
    setState(() {
      _clinics =
          _clinics.map((p) => p.copyWith(isFavorite: favIds.contains(p.placeId))).toList();
    });
  }

  // ---------- Location handling ----------
  Future<void> _ensureLocationEnabled() async {
    if (await Geolocator.isLocationServiceEnabled()) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Location is Off'),
        content: const Text('Please turn on location services to see nearby clinics.'),
        actions: [
          TextButton(
            onPressed: () async {
              await Geolocator.openLocationSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _determinePosition() async {
    setState(() => _loadingLocation = true);

    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() => _loadingLocation = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _loadingLocation = false);
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
              'Location permission is permanently denied. Please enable it in app settings.'),
          actions: [
            TextButton(
              onPressed: () async {
                await Geolocator.openAppSettings();
                Navigator.pop(context);
              },
              child: const Text('Open App Settings'),
            ),
          ],
        ),
      );
      setState(() => _loadingLocation = false);
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = LatLng(pos.latitude, pos.longitude);
      setState(() => _loadingLocation = false);

      await _fetchClinicsAround(_currentPosition!);
    } catch (e) {
      debugPrint('Error getting current location: $e');
      setState(() => _loadingLocation = false);
    }
  }

  // ---------- Fetch clinics ----------
  Future<void> _fetchClinicsAround(LatLng center) async {
    setState(() => _loadingClinics = true);
    try {
      final results = await _placesService.fetchNearbyClinics(
        center,
        'psychologists clinic',
        pages: 3, // fetch more
      );

      // Sort by distance
      if (_currentPosition != null) {
        results.sort((a, b) {
          final da = _distanceFromUser(a.location);
          final db = _distanceFromUser(b.location);
          return da.compareTo(db);
        });
      }

      final favIds = await _placesService.loadFavoriteIds();
      _clinics = results
          .map((p) => p.copyWith(isFavorite: favIds.contains(p.placeId)))
          .toList();

      _updateMarkers(_clinics);
    } catch (e) {
      debugPrint('Error fetching clinics: $e');
    } finally {
      setState(() => _loadingClinics = false);
    }
  }

  double _distanceFromUser(LatLng p) {
    if (_currentPosition == null) return double.infinity;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      p.latitude,
      p.longitude,
    );
  }

  void _updateMarkers(List<Place> clinics) {
    _markers.clear();
    _markerIds.clear();

    for (final c in clinics) {
      final id = MarkerId(c.placeId);
      _markerIds[c.placeId] = id;
      _markers.add(
        Marker(
          markerId: id,
          position: c.location,
          infoWindow: InfoWindow(title: c.name, snippet: c.address),
          onTap: () {
            _selectedClinic = c;
            _showClinicActions(c);
          },
        ),
      );
    }
    setState(() {});
  }

  void _ensureMarker(Place p) {
    if (_markerIds.containsKey(p.placeId)) return;
    final id = MarkerId(p.placeId);
    _markerIds[p.placeId] = id;
    _markers.add(
      Marker(
        markerId: id,
        position: p.location,
        infoWindow: InfoWindow(title: p.name, snippet: p.address),
        onTap: () {
          _selectedClinic = p;
          _showClinicActions(p);
        },
      ),
    );
    setState(() {});
  }

  void _goToClinic(Place clinic) {
    _ensureMarker(clinic);

    final markerId = _markerIds[clinic.placeId];
    _selectedClinic = clinic;

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(clinic.location, 16),
    );

    if (markerId != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _mapController?.showMarkerInfoWindow(markerId);
      });
    }

    _showClinicActions(clinic);
  }

  Future<void> _toggleFavorite(Place clinic) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to use favourites.')),
      );
      return;
    }

    final newFav = await _placesService.toggleFavorite(clinic);
    setState(() {
      _clinics = _clinics
          .map((p) =>
              p.placeId == clinic.placeId ? p.copyWith(isFavorite: newFav) : p)
          .toList();
    });
  }

  Future<Place> _ensureDetails(Place p) async {
    if (p.detailsFetched) return p;
    try {
      final updated = await _placesService.fetchPlaceDetails(p);
      setState(() {
        _clinics = _clinics
            .map((e) => e.placeId == updated.placeId ? updated : e)
            .toList();
      });
      return updated;
    } catch (_) {
      return p;
    }
  }

  String _todayHours(List<String> weekdayText) {
    final index = DateTime.now().weekday - 1; // 0-based for List
    if (index < 0 || index >= weekdayText.length) return '';
    return weekdayText[index];
  }

  void _showClinicActions(Place clinic) async {
    clinic = await _ensureDetails(clinic);

    final distKm = (_distanceFromUser(clinic.location) / 1000).toStringAsFixed(1);
    final fav = clinic.isFavorite;
    final openStr = clinic.openNow == null
        ? ''
        : (clinic.openNow! ? 'Open now' : 'Closed now');
    final todayStr = (clinic.weekdayText != null && clinic.weekdayText!.isNotEmpty)
        ? _todayHours(clinic.weekdayText!)
        : 'Hours not available';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            clinic.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            fav ? Icons.favorite : Icons.favorite_border,
                            color: fav ? Colors.red : Colors.grey,
                          ),
                          onPressed: () async {
                            await _toggleFavorite(clinic);
                            final idx =
                                _clinics.indexWhere((p) => p.placeId == clinic.placeId);
                            if (idx != -1) {
                              clinic = _clinics[idx];
                              setModalState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(clinic.address, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(
                      '⭐ ${clinic.rating.toStringAsFixed(1)}   •   $distKm km away',
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    if (openStr.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        openStr,
                        style: TextStyle(
                          fontSize: 13,
                          color: clinic.openNow == true ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      todayStr,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    if (clinic.weekdayText != null &&
                        clinic.weekdayText!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ExpansionTile(
                        title: const Text(
                          'Full Schedule',
                          style: TextStyle(fontSize: 14),
                        ),
                        children: clinic.weekdayText!
                            .map((line) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(line,
                                          style: const TextStyle(fontSize: 13))),
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.directions),
                            label: const Text('Directions'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.bgdarkgreen,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _openExternalDirections(clinic.location),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.map),
                            label: const Text('Open in Maps'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.backgroundGradientEnd,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () =>
                                _openExternalMaps(clinic.location, clinic.name),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // CALL BUTTON
                    ElevatedButton.icon(
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.facebookBlue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: clinic.phoneNumber == null
                          ? null
                          : () => _callNumber(clinic.phoneNumber!),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ---------- FAVOURITES BUTTON ----------
  void _openFavoritesSheet() async {
    final favPlaces = await _placesService.loadFavoritePlaces();
    if (favPlaces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No favourites yet.')),
      );
      return;
    }

    // DO NOT sort -> keep insertion order
    for (final p in favPlaces) {
      _ensureMarker(p);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: favPlaces.length,
          itemBuilder: (ctx2, i) {
            final p = favPlaces[i];
            final order = i + 1;
            final distKm = (_distanceFromUser(p.location) / 1000).toStringAsFixed(1);

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.backgroundGradientEnd,
                child: Text(order.toString(),
                    style: const TextStyle(color: Colors.white)),
              ),
              title: Text(p.name),
              subtitle: Text(
                '${p.address}\n$distKm km • ⭐ ${p.rating.toStringAsFixed(1)}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(ctx2);
                _goToClinic(p);
              },
            );
          },
        );
      },
    );
  }

  // ---------- External maps / call ----------
  Future<void> _openExternalDirections(LatLng dest) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${dest.latitude},${dest.longitude}&travelmode=driving';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openExternalMaps(LatLng dest, String name) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${dest.latitude},${dest.longitude}($name)';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callNumber(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cannot place call')));
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.backgroundGradientStart,
                AppColors.backgroundGradientEnd
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Psychologists Clinics',
              style: TextStyle(color: AppColors.textWhite),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.white),
                onPressed: _openFavoritesSheet,
                tooltip: 'Favourites',
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.backgroundGradientStart,
              AppColors.backgroundGradientEnd
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Map
            Expanded(
              flex: 2,
              child: _loadingLocation
                  ? const Center(child: CircularProgressIndicator())
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target:
                            _currentPosition ?? const LatLng(31.5204, 74.3587),
                        zoom: 14,
                      ),
                      myLocationEnabled: true,
                      markers: _markers,
                      onMapCreated: (c) => _mapController = c,
                    ),
            ),

            // Cards (no order, no timings, just rating & distance)
            Expanded(
              flex: 1,
              child: _loadingClinics
                  ? const Center(child: CircularProgressIndicator())
                  : _clinics.isEmpty
                      ? const Center(
                          child: Text(
                            'No clinics found nearby',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _clinics.length,
                          itemBuilder: (context, i) {
                            final clinic = _clinics[i];
                            final distKm =
                                _distanceFromUser(clinic.location) / 1000.0;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              child: ListTile(
                                title: Text(clinic.name),
                                subtitle: Text(
                                  '${clinic.address}\n'
                                  '${distKm.toStringAsFixed(1)} km • ⭐ ${clinic.rating.toStringAsFixed(1)}',
                                ),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: Icon(
                                    clinic.isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: clinic.isFavorite
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                  onPressed: () => _toggleFavorite(clinic),
                                ),
                                onTap: () => _goToClinic(clinic),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
