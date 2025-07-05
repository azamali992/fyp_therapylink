import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:therapylink/Views/custom_app_bar.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  late GoogleMapController mapController;
  final TextEditingController _searchController = TextEditingController();
  final Set<Marker> _markers = {};
  LatLng _center = const LatLng(31.5204, 74.3587); // Default to Pakistan (Lahore)
  bool _isLoading = true; // To show a loading indicator while getting the location

  // List of clinics (replace with real clinic data)
  final List<Map<String, dynamic>> _clinics = [
    {
      "name": "Psychologist Clinic 1",
      "rating": 4.5,
      "address": "123 Main St, Lahore, Pakistan",
      "phone": "123-456-7890",
      "lat": 31.5204,
      "lng": 74.3587,
    },
    {
      "name": "Mental Health Clinic 2",
      "rating": 4.0,
      "address": "456 Elm St, Lahore, Pakistan",
      "phone": "987-654-3210",
      "lat": 31.5300,
      "lng": 74.3600,
    },
    // Add more clinics...
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  // Get the user's current location
  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, handle appropriately
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        // Handle the case where permission is denied
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _center = LatLng(position.latitude, position.longitude);
      _isLoading = false; // Stop loading once the location is retrieved
    });

    // Move the camera to the user's location
    if (mapController != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLng(_center),
      );
    }

    // Add a marker for the user's location
    _markers.add(
      Marker(
        markerId: MarkerId('user_location'),
        position: _center,
        infoWindow: InfoWindow(title: 'Your Location'),
      ),
    );

    // Check nearby clinics
    _addNearbyClinics(_center);
  }

  // Add markers for nearby clinics based on user's location
  void _addNearbyClinics(LatLng userLocation) {
    _clinics.forEach((clinic) {
      final clinicLocation = LatLng(clinic['lat'], clinic['lng']);
      final distance = Geolocator.distanceBetween(
        userLocation.latitude,
        userLocation.longitude,
        clinicLocation.latitude,
        clinicLocation.longitude,
      );

      // Add a marker for the clinic if it's within 5 km of the user
      if (distance <= 5000) {
        _markers.add(
          Marker(
            markerId: MarkerId(clinic["name"]),
            position: clinicLocation,
            infoWindow: InfoWindow(
              title: clinic["name"],
              snippet: '${clinic["rating"]} Stars',
              onTap: () => _showClinicDetails(clinic),
            ),
          ),
        );
      }
    });
  }

  // Show clinic details in a dialog
  void _showClinicDetails(Map<String, dynamic> clinic) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(clinic["name"]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rating: ${clinic["rating"]}'),
              Text('Address: ${clinic["address"]}'),
              Text('Phone: ${clinic["phone"]}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green[700],
      ),
      home: Scaffold(
        appBar: CustomAppBar(screenWidth: screenWidth, screenHeight: screenHeight),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by location or psychologist name',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  filled: true,
                  fillColor: const Color.fromARGB(192, 255, 255, 255),
                ),
                onSubmitted: (value) {
                  // Implement search functionality (optional)
                },
              ),
            ),
            _isLoading
                ? Center(child: CircularProgressIndicator()) // Show a loading indicator while fetching the location
                : Expanded(
              child: GoogleMap(
                onMapCreated: (controller) {
                  mapController = controller;
                },
                initialCameraPosition: CameraPosition(
                  target: _center,
                  zoom: 11.0,
                ),
                markers: _markers,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
