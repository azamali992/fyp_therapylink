import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:therapylink/Views/custom_app_bar.dart';
import 'package:therapylink/utils/colors.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  _MapsPageState createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  final TextEditingController _searchController = TextEditingController();
  final Set<Marker> _markers = {};
  late GoogleMapController _mapController;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
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
                fillColor: Colors.white,
              ),
              onSubmitted: (value) {
                // Implement search functionality
              },
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(37.7749, -122.4194), // Default to San Francisco
                zoom: 12,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
              },
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
    );
  }

  Widget _buildClinicCard({
    required String name,
    required double rating,
    required String address,
    required String phone,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: ListTile(
        leading: const Icon(Icons.local_hospital, color: AppColors.bgpurple),
        title: Text(
          name,
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.call, color: AppColors.bgpurple),
              onPressed: () {
                // Implement call functionality
              },
            ),
            IconButton(
              icon: const Icon(Icons.message, color: AppColors.bgpurple),
              onPressed: () {
                // Implement message functionality
              },
            ),
          ],
        ),
        onTap: () {
          // Implement booking functionality
        },
      ),
    );
  }
}
