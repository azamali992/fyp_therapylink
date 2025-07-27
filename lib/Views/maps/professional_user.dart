import 'package:cloud_firestore/cloud_firestore.dart';

class ProfessionalUser {
  final String id;
  final String username;
  final String phone;
  final String gender;
  final String age;
  final String specialization;
  final String? profilePicUrl;
  final double? rating;
  final int? reviewCount;

  ProfessionalUser({
    required this.id,
    required this.username,
    required this.phone,
    required this.gender,
    required this.age,
    this.specialization = 'General Psychology',
    this.profilePicUrl,
    this.rating,
    this.reviewCount,
  });

  factory ProfessionalUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProfessionalUser(
      id: doc.id,
      username: data['username'] ?? 'Unknown',
      phone: data['phone'] ?? 'No phone provided',
      gender: data['gender'] ?? 'Not specified',
      age: data['age'] ?? 'Not specified',
      specialization: data['specialization'] ?? 'General Psychology',
      profilePicUrl: data['profilePicUrl'],
      rating: data['rating']?.toDouble(),
      reviewCount: data['reviewCount'],
    );
  }
}
