import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:therapylink/utils/colors.dart';
import 'package:intl/intl.dart';
import 'package:therapylink/services/summary_service.dart';

class ViewUserInsightsPage extends StatefulWidget {
  const ViewUserInsightsPage({super.key});

  @override
  State<ViewUserInsightsPage> createState() => _ViewUserInsightsPageState();
}

class _ViewUserInsightsPageState extends State<ViewUserInsightsPage>
    with SingleTickerProviderStateMixin {
  // State variables
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _notesController = TextEditingController();

  // List of appointments
  List<Map<String, dynamic>> _appointments = [];

  // Currently selected appointment/patient
  Map<String, dynamic>? _selectedAppointment;
  Map<String, dynamic>? _selectedPatientInfo;
  String? _chatSummary;
  bool _loadingSummary = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Load appointments for the currently logged in psychologist
  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _errorMessage = 'You must be logged in to view appointments';
          _isLoading = false;
        });
        return;
      }

      print('Fetching appointments for psychologist ID: ${currentUser.uid}');

      // Query appointments where this professional is assigned - without orderBy until index is created
      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('professionalId', isEqualTo: currentUser.uid)
          // .orderBy('date', descending: false) // Add back when index is created
          .get();

      if (appointmentsSnapshot.docs.isEmpty) {
        print('No appointments found for this professional');
        setState(() {
          _errorMessage = 'No appointments found';
          _isLoading = false;
          _appointments = [];
        });
        return;
      }

      // Process appointments
      final appointments = await Future.wait(
        appointmentsSnapshot.docs.map((doc) async {
          final data = doc.data();

          // Get patient information
          Map<String, dynamic> patientInfo = {};
          try {
            final patientDoc = await _firestore
                .collection('users')
                .doc(data['patientId'])
                .get();

            if (patientDoc.exists) {
              // Create a new mutable map
              patientInfo = Map<String, dynamic>.from(patientDoc.data() ?? {});
            }
          } catch (e) {
            print('Error fetching patient info: $e');
          }

          // Format appointment data
          return {
            'id': doc.id,
            'patientId': data['patientId'],
            'professionalId': data['professionalId'],
            'professionalName': data['professionalName'] ?? 'Unknown',
            'date': data['date'] ?? 'No date',
            'time': data['time'] ?? 'No time',
            'status': data['status'] ?? 'pending',
            'shareSummary': data['shareSummary'] ?? false,
            'createdAt': data['createdAt'] ?? Timestamp.now(),
            'patientInfo': patientInfo,
            'formattedDate': _formatAppointmentDate(data['date'], data['time']),
            'professionalNotes': data['professionalNotes'] ?? '',
          };
        }),
      );

      // Sort appointments by date manually until index is created
      appointments.sort((a, b) {
        try {
          final partsA = a['date'].split('/');
          final partsB = b['date'].split('/');

          if (partsA.length != 3 || partsB.length != 3) {
            return 0;
          }

          final dateA = DateTime(
              int.parse(partsA[2]), // year
              int.parse(partsA[1]), // month
              int.parse(partsA[0]) // day
              );

          final dateB = DateTime(
              int.parse(partsB[2]), // year
              int.parse(partsB[1]), // month
              int.parse(partsB[0]) // day
              );

          return dateA.compareTo(dateB);
        } catch (e) {
          print('Error sorting dates: $e');
          return 0; // If there's an error parsing, keep original order
        }
      });

      print('Found ${appointments.length} appointments');

      setState(() {
        _appointments = appointments;
        _isLoading = false;

        // Select first appointment by default if available
        if (appointments.isNotEmpty && _selectedAppointment == null) {
          _selectAppointment(appointments[0]);
        }
      });
    } catch (e) {
      print('Error loading appointments: $e');
      setState(() {
        _errorMessage = 'Error loading appointments: $e';
        _isLoading = false;
      });
    }
  }

  // Helper to format appointment date for display
  String _formatAppointmentDate(String? dateStr, String? timeStr) {
    if (dateStr == null || timeStr == null) return 'Date not available';

    try {
      // Format: "28/7/2025" -> DateTime
      final parts = dateStr.split('/');
      if (parts.length != 3) return dateStr;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final dateTime = DateTime(year, month, day);
      return '${DateFormat('EEEE, MMMM d, y').format(dateTime)} at $timeStr';
    } catch (e) {
      return '$dateStr at $timeStr';
    }
  }

  // Select an appointment and load related data
  Future<void> _selectAppointment(Map<String, dynamic> appointment) async {
    setState(() {
      _selectedAppointment = appointment;
      _selectedPatientInfo = appointment['patientInfo'];
      _chatSummary = null;
      _loadingSummary = true;
      _notesController.text = appointment['professionalNotes'] ?? '';
    });

    // Load chat summary if available
    if (appointment['shareSummary'] == true) {
      try {
        print('Fetching summary for patient: ${appointment['patientId']}');

        // First try to fetch an existing summary
        final summaryMap = await SummaryService.getLatestSummaryDocument(
          appointment['patientId'],
        );

        if (summaryMap != null &&
            summaryMap['summary'] != null &&
            summaryMap['summary'].isNotEmpty) {
          // Summary exists, use it
          print('Existing summary found');
          setState(() {
            _chatSummary = summaryMap['summary'];
            _loadingSummary = false;
          });
        } else {
          // No summary exists, generate one
          print('No existing summary found, generating a new one');
          final generatedSummary = await SummaryService.generateSummaryForUser(
            userId: appointment['patientId'],
            summaryType: 'therapeutic',
          );

          // Save the generated summary to Firestore for future use
          await SummaryService.saveSummary(
              appointment['patientId'], generatedSummary, 'therapeutic');

          setState(() {
            _chatSummary = generatedSummary;
            _loadingSummary = false;
          });
        }
      } catch (e) {
        print('Error loading or generating summary: $e');
        setState(() {
          _chatSummary =
              'Error loading or generating summary: $e. Please try again.';
          _loadingSummary = false;
        });
      }
    } else {
      setState(() {
        _chatSummary = null;
        _loadingSummary = false;
      });
    }
  }

  // Update appointment status
  Future<void> _updateAppointmentStatus(
      String appointmentId, String status) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({'status': status});

      // Refresh appointments
      _loadAppointments();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment $status')),
      );
    } catch (e) {
      print('Error updating appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update appointment: $e')),
      );
    }
  }

  // Save professional notes
  Future<void> _saveProfessionalNotes() async {
    if (_selectedAppointment == null) return;

    try {
      await _firestore
          .collection('appointments')
          .doc(_selectedAppointment!['id'])
          .update({'professionalNotes': _notesController.text});

      // Update local data
      _selectedAppointment!['professionalNotes'] = _notesController.text;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notes saved successfully')),
      );
    } catch (e) {
      print('Error saving notes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save notes: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth < 600 ? 220.0 : 280.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundGradientStart,
              AppColors.backgroundGradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Professional Dashboard',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(
                            'Patient Insights',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.refresh_rounded,
                            color: Colors.white),
                        onPressed: _loadAppointments,
                        tooltip: 'Refresh',
                      ),
                    ),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Loading patient insights...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _errorMessage.isNotEmpty && _appointments.isEmpty
                        ? _buildEmptyState()
                        : _buildMainContent(cardWidth),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(40),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 64,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Appointments Found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You don\'t have any patient appointments yet. Appointments will appear here once patients book sessions with you.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadAppointments,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.backgroundGradientStart,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(double cardWidth) {
    return Column(
      children: [
        // Appointments Section
        Container(
          height: 240,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.people_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Patient Appointments (${_appointments.length})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = _appointments[index];
                    final isSelected = _selectedAppointment != null &&
                        _selectedAppointment!['id'] == appointment['id'];

                    final patientInfo = appointment['patientInfo'];
                    final patientName =
                        patientInfo['username'] ?? 'Unknown Patient';
                    Color statusColor = getStatusColor(appointment['status']);

                    return Container(
                      width: cardWidth,
                      margin: const EdgeInsets.only(right: 16),
                      child: _buildAppointmentCard(
                          appointment, isSelected, patientName, statusColor),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Details Section
        Expanded(
          child: _selectedAppointment == null
              ? _buildSelectPrompt()
              : _buildPatientDetails(),
        ),
      ],
    );
  }

  Widget _buildAppointmentCard(
    Map<String, dynamic> appointment,
    bool isSelected,
    String patientName,
    Color statusColor,
  ) {
    return GestureDetector(
      onTap: () => _selectAppointment(appointment),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [
                    Colors.white,
                    Colors.white.withOpacity(0.95),
                  ]
                : [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.08),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.bgdarkgreen.withOpacity(0.5)
                : Colors.white.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.15 : 0.08),
              blurRadius: isSelected ? 20 : 12,
              offset: Offset(0, isSelected ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.bgpurple,
                        AppColors.bgpurple.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.bgpurple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      patientName.isNotEmpty
                          ? patientName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isSelected ? Colors.black87 : Colors.white,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment['time'],
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? Colors.grey[600]
                              : Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (appointment['shareSummary'] == true)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.bgdarkgreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.description_rounded,
                      color: AppColors.bgdarkgreen,
                      size: 16,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    appointment['status'].toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (appointment['status'] == 'pending')
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: Colors.orange,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectPrompt() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.touch_app_rounded,
                size: 48,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select an Appointment',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a patient appointment from above to view detailed insights and summaries',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientDetails() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Patient Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.bgdarkgreen, Color(0xFF2E7D5A)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _selectedPatientInfo?['username']?.isNotEmpty == true
                              ? _selectedPatientInfo!['username'][0]
                                  .toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.bgdarkgreen,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedPatientInfo?['username'] ??
                                'Unknown Patient',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Patient ID: ${_selectedAppointment!['patientId'].substring(0, 8)}...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_selectedAppointment!['status'] == 'pending') ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateAppointmentStatus(
                              _selectedAppointment!['id'], 'confirmed'),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Confirm'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateAppointmentStatus(
                              _selectedAppointment!['id'], 'cancelled'),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Cancel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Modern Tab Bar
          Container(
            padding: const EdgeInsets.all(4),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.black87,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_rounded,
                        color: _selectedAppointment!['shareSummary'] == true
                            ? AppColors.bgdarkgreen
                            : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text('Chat Summary'),
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Patient Info'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatSummaryTab(),
                _buildPatientInfoTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatSummaryTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: _selectedAppointment!['shareSummary'] == true
          ? _loadingSummary
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.bgdarkgreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const CircularProgressIndicator(
                          color: AppColors.bgdarkgreen,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Generating Therapeutic Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait while we analyze the conversation...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : _chatSummary == null
                  ? _buildErrorState()
                  : _buildSummaryContent()
          : _buildNoSummaryState(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to Load Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There was an issue loading the therapeutic summary. Please try again.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _selectAppointment(_selectedAppointment!),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.bgdarkgreen.withOpacity(0.1),
                  AppColors.bgdarkgreen.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.bgdarkgreen.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.bgdarkgreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.psychology_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Therapeutic Summary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.bgdarkgreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    _chatSummary!,
                    style: const TextStyle(
                      height: 1.6,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.bgpurple.withOpacity(0.1),
                  AppColors.bgpurple.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.bgpurple.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.bgpurple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.note_add_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Professional Notes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.bgpurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText:
                        'Add your professional observations and notes here...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.bgpurple, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _saveProfessionalNotes,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Save Notes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bgpurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSummaryState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Summary Not Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The patient has not shared their chat summary for this appointment.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfoTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoSection(
              'Personal Information',
              AppColors.bgdarkgreen,
              Icons.person_rounded,
              [
                _buildModernInfoRow(
                    'Name',
                    _selectedPatientInfo?['username'] ?? 'Not provided',
                    Icons.badge_rounded),
                _buildModernInfoRow(
                    'Gender',
                    _selectedPatientInfo?['gender'] ?? 'Not provided',
                    Icons.wc_rounded),
                _buildModernInfoRow(
                    'Age',
                    _selectedPatientInfo?['age']?.toString() ?? 'Not provided',
                    Icons.cake_rounded),
                _buildModernInfoRow(
                    'Email',
                    _selectedPatientInfo?['email'] ?? 'Not provided',
                    Icons.email_rounded),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoSection(
              'Appointment Details',
              AppColors.bgpurple,
              Icons.calendar_today_rounded,
              [
                _buildModernInfoRow('Date', _selectedAppointment!['date'],
                    Icons.date_range_rounded),
                _buildModernInfoRow('Time', _selectedAppointment!['time'],
                    Icons.access_time_rounded),
                _buildModernInfoRow(
                  'Status',
                  _selectedAppointment!['status'].toUpperCase(),
                  Icons.info_outline_rounded,
                  valueColor: getStatusColor(_selectedAppointment!['status']),
                ),
                _buildModernInfoRow(
                  'Summary Shared',
                  _selectedAppointment!['shareSummary'] ? 'Yes' : 'No',
                  _selectedAppointment!['shareSummary']
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  valueColor: _selectedAppointment!['shareSummary']
                      ? Colors.green
                      : Colors.red,
                ),
                _buildModernInfoRow(
                  'Created',
                  _formatTimestamp(
                      _selectedAppointment!['createdAt'] as Timestamp),
                  Icons.schedule_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
      String title, Color color, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: Colors.grey[600]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to get color based on status
  Color getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  // Format Firestore timestamp
  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return DateFormat('MMM d, y · h:mm a').format(dateTime);
  }
}
