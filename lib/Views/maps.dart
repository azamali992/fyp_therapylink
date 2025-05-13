import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:therapylink/Views/custom_app_bar.dart';
import 'package:therapylink/utils/colors.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  late GoogleMapController mapController;
  final TextEditingController _searchController = TextEditingController();
  final Set<Marker> _markers = {};

  final LatLng _center = const LatLng(31.5204, 74.3587); // Updated coordinates

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
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
        appBar:
            CustomAppBar(screenWidth: screenWidth, screenHeight: screenHeight),
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
                  // Implement search functionality
                },
              ),
            ),
            Expanded(
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _center,
                  zoom: 11.0,
                ),
                markers: _markers,
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildClinicCard(
                    name: 'Psychologist Clinic 1',
                    rating: 4.5,
                    address: '123 Main St, San Francisco, CA',
                    phone: '123-456-7890',
                  ),
                  _buildClinicCard(
                    name: 'Mental Health Clinic 2',
                    rating: 4.0,
                    address: '456 Elm St, San Francisco, CA',
                    phone: '987-654-3210',
                  ),
                  // Add more clinic cards as needed
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicCard({
    required String name,
    required double rating,
    required String address,
    required String phone,
  }) {
    return Card(
      color: AppColors.bgpurple, // Set the background color to purple
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_hospital, color: Colors.white),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              'Rating: $rating',
              style: const TextStyle(
                fontSize: 14.0,
                color: Colors.white70,
              ),
            ),
            Text(
              address,
              style: const TextStyle(
                fontSize: 14.0,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.call, color: Colors.white),
                  onPressed: () {
                    // Implement call functionality
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.message, color: Colors.white),
                  onPressed: () {
                    // Implement message functionality
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
