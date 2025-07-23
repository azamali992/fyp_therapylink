import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Firestore + Auth for favourites
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GooglePlacesService {
  final String apiKey;
  GooglePlacesService({required this.apiKey});

  // ---------------- GOOGLE APIs ----------------

  Future<LatLng> getLocationCoordinates(String location) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=$location&key=$apiKey';

    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch data from API: ${resp.statusCode}');
    }
    final data = json.decode(resp.body);
    if (data['status'] != 'OK') {
      throw Exception('Failed to get coordinates: ${data['status']}');
    }
    final lat = data['results'][0]['geometry']['location']['lat'];
    final lng = data['results'][0]['geometry']['location']['lng'];
    return LatLng(lat, lng);
  }

  /// Text Search (keyword + center + radius)
  /// Will follow next_page_token up to [pages] (max 3 by Google) to increase results.
  Future<List<Place>> fetchNearbyClinics(
    LatLng location,
    String keyword, {
    int pages = 3,
  }) async {
    List<Place> all = [];
    String? pageToken;

    for (int i = 0; i < pages; i++) {
      final url =
          'https://maps.googleapis.com/maps/api/place/textsearch/json'
          '?query=$keyword'
          '&location=${location.latitude},${location.longitude}'
          '&radius=5000'
          '&key=$apiKey'
          '${pageToken != null ? '&pagetoken=$pageToken' : ''}';

      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode != 200) {
        throw Exception('Failed to fetch data from API: ${resp.statusCode}');
      }
      final data = json.decode(resp.body);
      if (data['status'] != 'OK') {
        // If status is "INVALID_REQUEST" for next_page_token, just break
        if (data['status'] == 'INVALID_REQUEST') break;
        throw Exception('Failed to load places: ${data['status']}');
      }

      final results = data['results'] as List<dynamic>;
      all.addAll(
        results.map((e) => Place.fromJson(e as Map<String, dynamic>)),
      );

      pageToken = data['next_page_token'];
      if (pageToken == null) break;

      // Google needs a short delay before next page token works
      await Future.delayed(const Duration(seconds: 2));
    }

    return all;
  }

  /// Place Details (to get opening hours, phone)
  Future<Place> fetchPlaceDetails(Place place) async {
    final fields =
        'opening_hours,formatted_phone_number,international_phone_number';
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${place.placeId}&fields=$fields&key=$apiKey';

    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch place details: ${resp.statusCode}');
    }
    final data = json.decode(resp.body);
    if (data['status'] != 'OK') {
      throw Exception('Place details error: ${data['status']}');
    }

    final result = data['result'] as Map<String, dynamic>;
    final opening = result['opening_hours'];
    bool? openNow;
    List<String>? weekdayText;
    if (opening != null) {
      openNow = opening['open_now'] as bool?;
      if (opening['weekday_text'] != null) {
        weekdayText = List<String>.from(opening['weekday_text']);
      }
    }

    final phone = result['formatted_phone_number'] ??
        result['international_phone_number'];

    return place.copyWith(
      openNow: openNow,
      weekdayText: weekdayText,
      phoneNumber: phone,
      detailsFetched: true,
    );
  }

  // ---------------- FAVOURITES ----------------

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _favCol(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('favorites');

  Future<Set<String>> loadFavoriteIds() async {
    final uid = _uid;
    if (uid == null) return {};
    final snap = await _favCol(uid).get();
    return snap.docs.map((d) => d.id).toSet();
  }

  /// Load favourites in the order user added them
  Future<List<Place>> loadFavoritePlaces() async {
    final uid = _uid;
    if (uid == null) return [];
    final snap = await _favCol(uid)
        .orderBy('addedAt', descending: false)
        .get();

    return snap.docs
        .map((d) => Place.fromFirestore(d.data(), d.id))
        .toList(growable: false);
  }

  Future<void> addFavorite(Place p) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in');

    final data = p.toFirestoreMap()
      ..['addedAt'] = FieldValue.serverTimestamp();

    await _favCol(uid).doc(p.placeId).set(data);
  }

  Future<void> removeFavorite(String placeId) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in');
    await _favCol(uid).doc(placeId).delete();
  }

  Future<bool> toggleFavorite(Place p) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in');
    final ref = _favCol(uid).doc(p.placeId);
    final exists = (await ref.get()).exists;
    if (exists) {
      await ref.delete();
      return false;
    } else {
      final data = p.toFirestoreMap()..['addedAt'] = FieldValue.serverTimestamp();
      await ref.set(data);
      return true;
    }
  }
}

class Place {
  final String name;
  final String address;
  final LatLng location;
  final String placeId;
  final double rating;
  final bool isFavorite;

  // timings & phone
  final bool? openNow;
  final List<String>? weekdayText;
  final String? phoneNumber;
  final bool detailsFetched;

  Place({
    required this.name,
    required this.address,
    required this.location,
    required this.placeId,
    required this.rating,
    this.isFavorite = false,
    this.openNow,
    this.weekdayText,
    this.phoneNumber,
    this.detailsFetched = false,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    bool? openNow;
    if (json['opening_hours'] != null) {
      openNow = json['opening_hours']['open_now'] as bool?;
    }
    return Place(
      name: json['name'] ?? '',
      address: json['formatted_address'] ?? '',
      location: LatLng(
        (json['geometry']['location']['lat'] as num).toDouble(),
        (json['geometry']['location']['lng'] as num).toDouble(),
      ),
      placeId: json['place_id'] ?? '',
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : 0.0,
      openNow: openNow,
    );
  }

  factory Place.fromFirestore(Map<String, dynamic> data, String id) {
    return Place(
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      location: LatLng((data['lat'] ?? 0.0) * 1.0, (data['lng'] ?? 0.0) * 1.0),
      placeId: id,
      rating: (data['rating'] ?? 0.0) * 1.0,
      isFavorite: (data['isFavorite'] ?? true),
      openNow: data['openNow'],
      weekdayText: data['weekdayText'] != null
          ? List<String>.from(data['weekdayText'])
          : null,
      phoneNumber: data['phoneNumber'],
      detailsFetched: data['detailsFetched'] ?? false,
    );
  }

  Map<String, dynamic> toFirestoreMap() => {
        'name': name,
        'address': address,
        'lat': location.latitude,
        'lng': location.longitude,
        'rating': rating,
        'isFavorite': isFavorite,
        'openNow': openNow,
        'weekdayText': weekdayText,
        'phoneNumber': phoneNumber,
        'detailsFetched': detailsFetched,
      };

  Place copyWith({
    bool? isFavorite,
    bool? openNow,
    List<String>? weekdayText,
    String? phoneNumber,
    bool? detailsFetched,
  }) =>
      Place(
        name: name,
        address: address,
        location: location,
        placeId: placeId,
        rating: rating,
        isFavorite: isFavorite ?? this.isFavorite,
        openNow: openNow ?? this.openNow,
        weekdayText: weekdayText ?? this.weekdayText,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        detailsFetched: detailsFetched ?? this.detailsFetched,
      );
}
