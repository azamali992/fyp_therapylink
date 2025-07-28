import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:therapylink/utils/colors.dart';

import 'google_places_service.dart';
import 'professional_user.dart';
import 'professional_user_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

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

  // Professional users
  List<ProfessionalUser> _professionals = [];
  bool _loadingProfessionals = false;
  bool _showProfessionalsTab = false;

  final GooglePlacesService _placesService = GooglePlacesService(
    apiKey: 'AIzaSyBRGgGd3AhtZrH1ZWy3i80oA3XNvUf3JHE',
  );

  final ProfessionalUserService _professionalService =
      ProfessionalUserService();

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await _ensureLocationEnabled();
    await _determinePosition();
    await _mergeFavsIntoCurrentList();

    // Load registered professionals
    _fetchRegisteredProfessionals();
  }

  Future<void> _fetchRegisteredProfessionals() async {
    setState(() => _loadingProfessionals = true);
    try {
      // First debug all user roles in the database
      await _professionalService.debugUserRoles();

      final professionals =
          await _professionalService.fetchMentalHealthProfessionals();

      // Debug what we got
      print('Professionals found: ${professionals.length}');
      for (var prof in professionals) {
        print('Professional: ${prof.username}, ID: ${prof.id}');
      }

      setState(() {
        _professionals = professionals;
      });
    } catch (e) {
      debugPrint('Error loading professionals: $e');
    } finally {
      setState(() => _loadingProfessionals = false);
    }
  }

  Future<void> _mergeFavsIntoCurrentList() async {
    final favIds = await _placesService.loadFavoriteIds();
    setState(() {
      _clinics = _clinics
          .map((p) => p.copyWith(isFavorite: favIds.contains(p.placeId)))
          .toList();
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
        content: const Text(
            'Please turn on location services to see nearby clinics.'),
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

    final distKm =
        (_distanceFromUser(clinic.location) / 1000).toStringAsFixed(1);
    final fav = clinic.isFavorite;
    final openStr = clinic.openNow == null
        ? ''
        : (clinic.openNow! ? 'Open now' : 'Closed now');
    final todayStr =
        (clinic.weekdayText != null && clinic.weekdayText!.isNotEmpty)
            ? _todayHours(clinic.weekdayText!)
            : 'Hours not available';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xFFF8F9FA),
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Header with name and favorite
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  clinic.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgdarkgreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Healthcare Facility',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.bgdarkgreen,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: fav ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(
                                fav ? Icons.favorite : Icons.favorite_border,
                                color: fav ? Colors.red : Colors.grey,
                                size: 24,
                              ),
                              onPressed: () async {
                                await _toggleFavorite(clinic);
                                final idx = _clinics
                                    .indexWhere((p) => p.placeId == clinic.placeId);
                                if (idx != -1) {
                                  clinic = _clinics[idx];
                                  setModalState(() {});
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Info cards
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(Icons.location_on, clinic.address, Colors.red),
                            const Divider(height: 20),
                            _buildInfoRow(
                              Icons.star,
                              '${clinic.rating.toStringAsFixed(1)} rating',
                              Colors.amber,
                            ),
                            const Divider(height: 20),
                            _buildInfoRow(
                              Icons.directions_car,
                              '$distKm km away',
                              AppColors.bgdarkgreen,
                            ),
                            if (openStr.isNotEmpty) ...[
                              const Divider(height: 20),
                              _buildInfoRow(
                                clinic.openNow == true ? Icons.access_time : Icons.access_time_filled,
                                openStr,
                                clinic.openNow == true ? Colors.green : Colors.red,
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Hours section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.schedule,
                                  color: AppColors.bgdarkgreen,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Hours Today',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              todayStr,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            if (clinic.weekdayText != null &&
                                clinic.weekdayText!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                title: const Text(
                                  'View Full Schedule',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.bgdarkgreen,
                                  ),
                                ),
                                children: clinic.weekdayText!
                                    .map((line) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 0,
                                            vertical: 4,
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              line,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.directions,
                              label: 'Directions',
                              color: AppColors.bgdarkgreen,
                              onPressed: () => _openExternalDirections(clinic.location),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.map,
                              label: 'Open Maps',
                              color: AppColors.backgroundGradientEnd,
                              onPressed: () => _openExternalMaps(clinic.location, clinic.name),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Call button
                      SizedBox(
                        width: double.infinity,
                        child: _buildActionButton(
                          icon: Icons.call,
                          label: clinic.phoneNumber != null ? 'Call Now' : 'Phone Not Available',
                          color: clinic.phoneNumber != null ? AppColors.facebookBlue : Colors.grey,
                          onPressed: clinic.phoneNumber == null
                              ? null
                              : () => _callNumber(clinic.phoneNumber!),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      onPressed: onPressed,
    );
  }

  // ---------- FAVOURITES BUTTON ----------
  void _openFavoritesSheet() async {
    final favPlaces = await _placesService.loadFavoritePlaces();
    if (favPlaces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No favourites yet.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // DO NOT sort -> keep insertion order
    for (final p in favPlaces) {
      _ensureMarker(p);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xFFF8F9FA),
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle and header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Your Favourite Clinics',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Favorites list
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: favPlaces.length,
                  itemBuilder: (ctx2, i) {
                    final p = favPlaces[i];
                    final order = i + 1;
                    final distKm =
                        (_distanceFromUser(p.location) / 1000).toStringAsFixed(1);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.backgroundGradientStart,
                                AppColors.backgroundGradientEnd,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            order.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        title: Text(
                          p.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              p.address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.directions_car,
                                  size: 16,
                                  color: AppColors.bgdarkgreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$distKm km',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.bgdarkgreen,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  p.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.bgdarkgreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppColors.bgdarkgreen,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(ctx2);
                          _goToClinic(p);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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

  void _showProfessionalDetails(ProfessionalUser professional) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xFFF8F9FA),
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Professional header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.bgdarkgreen,
                        AppColors.backgroundGradientEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: professional.profilePicUrl != null
                            ? CircleAvatar(
                                radius: 30,
                                backgroundImage:
                                    NetworkImage(professional.profilePicUrl!),
                              )
                            : const CircleAvatar(
                                radius: 30,
                                backgroundColor: AppColors.bgdarkgreen,
                                child: Icon(Icons.person, color: Colors.white, size: 30),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              professional.username,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                professional.specialization,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (professional.rating != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${professional.rating!.toStringAsFixed(1)} (${professional.reviewCount ?? 0} reviews)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Info section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildModernInfoRow(Icons.cake, 'Age: ${professional.age}'),
                      const Divider(height: 20),
                      _buildModernInfoRow(Icons.wc, 'Gender: ${professional.gender}'),
                      const Divider(height: 20),
                      _buildModernInfoRow(Icons.phone, professional.phone),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.call,
                        label: 'Contact',
                        color: AppColors.bgdarkgreen,
                        onPressed: () => _callNumber(professional.phone),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.calendar_month,
                        label: 'Book Appointment',
                        color: AppColors.backgroundGradientEnd,
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showAppointmentBookingDialog(professional);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.bgdarkgreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.bgdarkgreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  void _showAppointmentBookingDialog(ProfessionalUser professional) {
    // Variables for appointment details
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedTime = '09:00 AM';
    bool consentToShareSummary = false;

    // Available time slots
    final List<String> timeSlots = [
      '09:00 AM',
      '10:00 AM',
      '11:00 AM',
      '12:00 PM',
      '01:00 PM',
      '02:00 PM',
      '03:00 PM',
      '04:00 PM',
      '05:00 PM'
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Book Appointment with ${professional.username}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Date:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListTile(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 30)),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AppColors.backgroundGradientEnd,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null && picked != selectedDate) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        title: Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Time:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedTime,
                          items: timeSlots.map((String time) {
                            return DropdownMenuItem<String>(
                              value: time,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(time),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedTime = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Consent checkbox for sharing chat summary
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'I consent to share my chat summary with the psychologist',
                        style: TextStyle(fontSize: 14),
                      ),
                      value: consentToShareSummary,
                      activeColor: AppColors.bgdarkgreen,
                      onChanged: (bool? value) {
                        if (value != null) {
                          setState(() {
                            consentToShareSummary = value;
                          });

                          // If user checked the consent box, show info dialog
                          if (value) {
                            Future.delayed(const Duration(milliseconds: 300),
                                () {
                              _showChatSummaryConsentInfo();
                            });
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: const Text(
                    'Book',
                    style: TextStyle(color: AppColors.bgdarkgreen),
                  ),
                  onPressed: () {
                    _bookAppointment(
                      professional: professional,
                      date: selectedDate,
                      time: selectedTime,
                      shareSummary: consentToShareSummary,
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChatSummaryConsentInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.backgroundGradientEnd),
              SizedBox(width: 8),
              Text('Chat Summary Sharing'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your chat summary will help the psychologist understand your concerns before the appointment.',
                style: TextStyle(fontSize: 15),
              ),
              SizedBox(height: 12),
              Text(
                'This includes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Recent chat interactions with the AI assistant'),
              Text('• Key concerns and topics discussed'),
              Text('• Mood analysis data if available'),
              SizedBox(height: 12),
              Text(
                'Note: You can withdraw your consent at any time by contacting us.',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('OK, I understand'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Future<void> _bookAppointment({
    required ProfessionalUser professional,
    required DateTime date,
    required String time,
    required bool shareSummary,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to book appointments')),
      );
      return;
    }

    try {
      // Format date for Firestore
      final formattedDate = '${date.day}/${date.month}/${date.year}';

      // Save appointment in Firestore
      final appointmentRef =
          await FirebaseFirestore.instance.collection('appointments').add({
        'patientId': user.uid,
        'professionalId': professional.id,
        'professionalName': professional.username,
        'date': formattedDate,
        'time': time,
        'status': 'pending',
        'shareSummary': shareSummary,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update the professional's patient list
      await _professionalService.addPatientToProfessional(
          professional.id, user.uid);

      print('Appointment booked with ID: ${appointmentRef.id}');
      print('Updated patient list for professional ${professional.id}');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Appointment with ${professional.username} booked successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error booking appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

            // Toggle tabs - Clinics / Registered Professionals
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _showProfessionalsTab = false);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: !_showProfessionalsTab
                                ? const LinearGradient(
                                    colors: [
                                      AppColors.backgroundGradientStart,
                                      AppColors.backgroundGradientEnd,
                                    ],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 18,
                                color: !_showProfessionalsTab
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Nearby Clinics',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: !_showProfessionalsTab
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: !_showProfessionalsTab
                                      ? Colors.white
                                      : Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _showProfessionalsTab = true);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: _showProfessionalsTab
                                ? const LinearGradient(
                                    colors: [
                                      AppColors.bgdarkgreen,
                                      AppColors.backgroundGradientEnd,
                                    ],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.psychology,
                                size: 18,
                                color: _showProfessionalsTab
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Psychologists',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: _showProfessionalsTab
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: _showProfessionalsTab
                                      ? Colors.white
                                      : Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Either Clinics or Professionals list based on toggle
            Expanded(
              flex: 1,
              child: _showProfessionalsTab
                  ? _buildProfessionalsList()
                  : _buildClinicsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicsList() {
    return _loadingClinics
        ? const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          )
        : _clinics.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_off,
                      color: Colors.white70,
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No clinics found nearby',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ListView.builder(
                  itemCount: _clinics.length,
                  itemBuilder: (context, i) {
                    final clinic = _clinics[i];
                    final distKm = _distanceFromUser(clinic.location) / 1000.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Color(0xFFF8F9FA),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.bgdarkgreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.local_hospital,
                            color: AppColors.bgdarkgreen,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          clinic.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              clinic.address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.directions_car,
                                  size: 14,
                                  color: AppColors.bgdarkgreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${distKm.toStringAsFixed(1)} km',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.bgdarkgreen,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  clinic.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: clinic.isFavorite
                                ? Colors.red.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            clinic.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: clinic.isFavorite ? Colors.red : Colors.grey,
                            size: 20,
                          ),
                        ),
                        onTap: () => _goToClinic(clinic),
                      ),
                    );
                  },
                ),
              );
  }

  Widget _buildProfessionalsList() {
    return _loadingProfessionals
        ? const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          )
        : _professionals.isEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_off,
                      color: Colors.white70,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No registered psychologists found',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.bgdarkgreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _fetchRegisteredProfessionals,
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ListView.builder(
                  itemCount: _professionals.length,
                  itemBuilder: (context, i) {
                    final professional = _professionals[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Color(0xFFF8F9FA),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.bgdarkgreen,
                                AppColors.backgroundGradientEnd,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: professional.profilePicUrl != null
                              ? CircleAvatar(
                                  radius: 24,
                                  backgroundImage:
                                      NetworkImage(professional.profilePicUrl!),
                                )
                              : const CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.person,
                                    color: AppColors.bgdarkgreen,
                                    size: 24,
                                  ),
                                ),
                        ),
                        title: Text(
                          professional.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.bgdarkgreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                professional.specialization,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.bgdarkgreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.wc,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  professional.gender,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.cake,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${professional.age} years',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.bgdarkgreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppColors.bgdarkgreen,
                          ),
                        ),
                        onTap: () => _showProfessionalDetails(professional),
                      ),
                    );
                  },
                ),
              );
  }
}
