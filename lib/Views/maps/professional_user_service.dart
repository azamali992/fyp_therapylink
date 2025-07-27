import 'package:cloud_firestore/cloud_firestore.dart';
import 'professional_user.dart';

class ProfessionalUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ProfessionalUser>> fetchMentalHealthProfessionals() async {
    try {
      // Try to fetch professionals by checking both possible representations of the role
      // First try with the enum's toString representation
      final querySnapshot = await _firestore.collection('users').where('role',
          whereIn: [
            'UserRole.MentalHealthProfessional',
            'MentalHealthProfessional'
          ]).get();

      // Debug print to check if we're getting any results
      print('Found ${querySnapshot.docs.length} mental health professionals');

      // Print details of found professionals
      for (var doc in querySnapshot.docs) {
        print(
            'Professional: ${doc.id} - ${doc.data()['username']} - Role: ${doc.data()['role']}');
      }

      return querySnapshot.docs
          .map((doc) => ProfessionalUser.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching mental health professionals: $e');
      return [];
    }
  }

  Future<ProfessionalUser?> getProfessionalById(String id) async {
    try {
      final doc = await _firestore.collection('users').doc(id).get();
      if (doc.exists) {
        return ProfessionalUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching professional by ID: $e');
      return null;
    }
  }

  // Debug method to check all users and their roles
  Future<void> debugUserRoles() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();

      print("DEBUGGING USER ROLES:");
      print("Total users found: ${querySnapshot.docs.length}");

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        print(
            "User ID: ${doc.id}, Role: ${data['role']}, Username: ${data['username']}");
      }
    } catch (e) {
      print('Error debugging user roles: $e');
    }
  }

  /// Updates the professional's patient list when a new appointment is booked
  Future<void> addPatientToProfessional(
      String professionalId, String patientId) async {
    try {
      // First, check if the professional document exists in the professionals collection
      final professionalDoc = await _firestore
          .collection('professionals')
          .doc(professionalId)
          .get();

      if (professionalDoc.exists) {
        // Professional document exists, update the patients array
        await _firestore
            .collection('professionals')
            .doc(professionalId)
            .update({
          'patients': FieldValue.arrayUnion([patientId]),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // Create a new professional document with this patient
        await _firestore.collection('professionals').doc(professionalId).set({
          'professionalId': professionalId,
          'patients': [patientId],
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      print('Patient $patientId added to professional $professionalId\'s list');
    } catch (e) {
      print('Error updating professional\'s patient list: $e');
    }
  }

  /// Retrieves all patients associated with a professional
  Future<List<String>> getProfessionalPatients(String professionalId) async {
    try {
      final professionalDoc = await _firestore
          .collection('professionals')
          .doc(professionalId)
          .get();

      if (professionalDoc.exists) {
        final data = professionalDoc.data();
        if (data != null && data.containsKey('patients')) {
          return List<String>.from(data['patients']);
        }
      }

      return []; // Return empty list if no patients or document doesn't exist
    } catch (e) {
      print('Error getting professional\'s patients: $e');
      return [];
    }
  }
}
