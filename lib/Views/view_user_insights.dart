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
    final cardWidth = screenWidth < 600 ? 160.0 : 200.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Patient Insights',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.backgroundGradientStart,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
            tooltip: 'Refresh',
          )
        ],
      ),
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : _errorMessage.isNotEmpty && _appointments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 64,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadAppointments,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.backgroundGradientStart,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Horizontal appointment tabs
                      Container(
                        height: 140,
                        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 4, bottom: 8),
                              child: Text(
                                'Appointments (${_appointments.length})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _appointments.length,
                                itemBuilder: (context, index) {
                                  final appointment = _appointments[index];
                                  final isSelected =
                                      _selectedAppointment != null &&
                                          _selectedAppointment!['id'] ==
                                              appointment['id'];

                                  final patientInfo =
                                      appointment['patientInfo'];
                                  final patientName = patientInfo['username'] ??
                                      'Unknown Patient';

                                  // Determine status color
                                  Color statusColor =
                                      getStatusColor(appointment['status']);

                                  return Card(
                                    elevation: isSelected ? 4 : 1,
                                    margin: const EdgeInsets.only(right: 12),
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: isSelected
                                          ? BorderSide(
                                              color: AppColors.bgdarkgreen,
                                              width: 2)
                                          : BorderSide.none,
                                    ),
                                    child: InkWell(
                                      onTap: () =>
                                          _selectAppointment(appointment),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        width: cardWidth,
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor:
                                                      AppColors.bgpurple,
                                                  child: Text(
                                                    patientName.isNotEmpty
                                                        ? patientName[0]
                                                            .toUpperCase()
                                                        : '?',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    patientName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                                if (appointment[
                                                        'shareSummary'] ==
                                                    true)
                                                  const Tooltip(
                                                    message: 'Summary shared',
                                                    child: Icon(
                                                      Icons.description,
                                                      color:
                                                          AppColors.bgdarkgreen,
                                                      size: 16,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '${appointment['date']} at ${appointment['time']}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[700],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            const Spacer(),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                // Status badge
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: statusColor
                                                        .withOpacity(0.1),
                                                    border: Border.all(
                                                        color: statusColor),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Text(
                                                    appointment['status']
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      color: statusColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 9,
                                                    ),
                                                  ),
                                                ),
                                                // Action indicator for pending
                                                if (appointment['status'] ==
                                                    'pending')
                                                  const Icon(
                                                    Icons.more_horiz,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Details section (takes remaining space)
                      Expanded(
                        child: _selectedAppointment == null
                            ? Center(
                                child: Text(
                                  'Select an appointment to view patient details',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 18,
                                  ),
                                ),
                              )
                            : Card(
                                margin: const EdgeInsets.all(12),
                                color: Colors.white.withOpacity(0.9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    // Patient header with actions for pending appointments
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: const BoxDecoration(
                                        color: AppColors.bgdarkgreen,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 24,
                                                backgroundColor: Colors.white,
                                                child: Text(
                                                  _selectedPatientInfo?[
                                                                  'username']
                                                              ?.isNotEmpty ==
                                                          true
                                                      ? _selectedPatientInfo![
                                                              'username'][0]
                                                          .toUpperCase()
                                                      : '?',
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.bgdarkgreen,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      _selectedPatientInfo?[
                                                              'username'] ??
                                                          'Unknown Patient',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Action buttons for pending appointments in a separate row
                                          if (_selectedAppointment!['status'] ==
                                              'pending')
                                            Container(
                                              margin:
                                                  const EdgeInsets.only(top: 6),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  ElevatedButton.icon(
                                                    onPressed: () =>
                                                        _updateAppointmentStatus(
                                                            _selectedAppointment![
                                                                'id'],
                                                            'confirmed'),
                                                    icon: const Icon(
                                                        Icons.check,
                                                        size: 16),
                                                    label:
                                                        const Text('Confirm'),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.green,
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 8),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  ElevatedButton.icon(
                                                    onPressed: () =>
                                                        _updateAppointmentStatus(
                                                            _selectedAppointment![
                                                                'id'],
                                                            'cancelled'),
                                                    icon: const Icon(
                                                        Icons.close,
                                                        size: 10),
                                                    label: const Text('Cancel'),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.red,
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 8),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    // Tab bar for different sections
                                    TabBar(
                                      controller: _tabController,
                                      labelColor: AppColors.bgdarkgreen,
                                      unselectedLabelColor: Colors.grey,
                                      indicatorColor: AppColors.bgdarkgreen,
                                      tabs: [
                                        Tab(
                                          text: 'Chat Summary',
                                          icon: Icon(
                                            Icons.chat,
                                            color: _selectedAppointment![
                                                        'shareSummary'] ==
                                                    true
                                                ? AppColors.bgdarkgreen
                                                : Colors.grey,
                                          ),
                                        ),
                                        const Tab(
                                          text: 'Patient Info',
                                          icon: Icon(Icons.person),
                                        ),
                                      ],
                                    ),

                                    // Tab content
                                    Expanded(
                                      child: TabBarView(
                                        controller: _tabController,
                                        children: [
                                          // Chat Summary Tab
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: _selectedAppointment![
                                                        'shareSummary'] ==
                                                    true
                                                ? _loadingSummary
                                                    ? const Center(
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            CircularProgressIndicator(
                                                              color: AppColors
                                                                  .bgdarkgreen,
                                                            ),
                                                            SizedBox(
                                                                height: 16),
                                                            Text(
                                                              'Generating therapeutic summary...\nThis may take a moment.',
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    : _chatSummary == null
                                                        ? Center(
                                                            child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .error_outline,
                                                                  size: 64,
                                                                  color: Colors
                                                                      .red[300],
                                                                ),
                                                                const SizedBox(
                                                                    height: 16),
                                                                const Text(
                                                                  'Unable to load summary.\nPlease try again.',
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .grey,
                                                                    fontSize:
                                                                        16,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 16),
                                                                ElevatedButton
                                                                    .icon(
                                                                  onPressed: () =>
                                                                      _selectAppointment(
                                                                          _selectedAppointment!),
                                                                  icon: const Icon(
                                                                      Icons
                                                                          .refresh),
                                                                  label: const Text(
                                                                      'Try Again'),
                                                                  style: ElevatedButton
                                                                      .styleFrom(
                                                                    backgroundColor:
                                                                        AppColors
                                                                            .bgdarkgreen,
                                                                    foregroundColor:
                                                                        Colors
                                                                            .white,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          )
                                                        : SingleChildScrollView(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                const Text(
                                                                  'Therapeutic Summary',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        18,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: AppColors
                                                                        .bgdarkgreen,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 8),
                                                                Container(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          16),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                            .grey[
                                                                        100],
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(8),
                                                                    border:
                                                                        Border
                                                                            .all(
                                                                      color: Colors
                                                                              .grey[
                                                                          300]!,
                                                                    ),
                                                                  ),
                                                                  child: Text(
                                                                    _chatSummary!,
                                                                    style:
                                                                        const TextStyle(
                                                                      height:
                                                                          1.5,
                                                                      fontSize:
                                                                          16,
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 20),
                                                                const Text(
                                                                  'Professional Notes',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        18,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: AppColors
                                                                        .bgpurple,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 8),
                                                                TextField(
                                                                  controller:
                                                                      _notesController,
                                                                  maxLines: 5,
                                                                  decoration:
                                                                      InputDecoration(
                                                                    hintText:
                                                                        'Add your professional notes here...',
                                                                    border:
                                                                        OutlineInputBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              8),
                                                                    ),
                                                                    filled:
                                                                        true,
                                                                    fillColor:
                                                                        Colors
                                                                            .white,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 12),
                                                                Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .centerRight,
                                                                  child:
                                                                      ElevatedButton
                                                                          .icon(
                                                                    onPressed:
                                                                        _saveProfessionalNotes,
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .save),
                                                                    label: const Text(
                                                                        'Save Notes'),
                                                                    style: ElevatedButton
                                                                        .styleFrom(
                                                                      backgroundColor:
                                                                          AppColors
                                                                              .bgpurple,
                                                                      foregroundColor:
                                                                          Colors
                                                                              .white,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          )
                                                : Center(
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.lock,
                                                          size: 64,
                                                          color:
                                                              Colors.grey[400],
                                                        ),
                                                        const SizedBox(
                                                            height: 16),
                                                        const Text(
                                                          'Patient has not shared their chat summary',
                                                          style: TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 16,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                          ),

                                          // Patient Info Tab
                                          SingleChildScrollView(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Personal Information',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppColors.bgdarkgreen,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  _buildInfoRow(
                                                    'Name',
                                                    _selectedPatientInfo?[
                                                            'username'] ??
                                                        'Not provided',
                                                    Icons.person,
                                                  ),
                                                  _buildInfoRow(
                                                    'Gender',
                                                    _selectedPatientInfo?[
                                                            'gender'] ??
                                                        'Not provided',
                                                    Icons.wc,
                                                  ),
                                                  _buildInfoRow(
                                                    'Age',
                                                    _selectedPatientInfo?['age']
                                                            ?.toString() ??
                                                        'Not provided',
                                                    Icons.cake,
                                                  ),
                                                  _buildInfoRow(
                                                    'Email',
                                                    _selectedPatientInfo?[
                                                            'email'] ??
                                                        'Not provided',
                                                    Icons.email,
                                                  ),
                                                  const Divider(height: 32),
                                                  const Text(
                                                    'Appointment Details',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors.bgpurple,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  _buildInfoRow(
                                                    'Date',
                                                    _selectedAppointment![
                                                        'date'],
                                                    Icons.calendar_today,
                                                  ),
                                                  _buildInfoRow(
                                                    'Time',
                                                    _selectedAppointment![
                                                        'time'],
                                                    Icons.access_time,
                                                  ),
                                                  _buildInfoRow(
                                                    'Status',
                                                    _selectedAppointment![
                                                            'status']
                                                        .toUpperCase(),
                                                    Icons.info_outline,
                                                    getStatusColor(
                                                        _selectedAppointment![
                                                            'status']),
                                                  ),
                                                  _buildInfoRow(
                                                    'Summary Shared',
                                                    _selectedAppointment![
                                                            'shareSummary']
                                                        ? 'Yes'
                                                        : 'No',
                                                    _selectedAppointment![
                                                            'shareSummary']
                                                        ? Icons
                                                            .check_circle_outline
                                                        : Icons.cancel_outlined,
                                                    _selectedAppointment![
                                                            'shareSummary']
                                                        ? Colors.green
                                                        : Colors.red,
                                                  ),
                                                  _buildInfoRow(
                                                    'Created',
                                                    _formatTimestamp(
                                                        _selectedAppointment![
                                                                'createdAt']
                                                            as Timestamp),
                                                    Icons.access_time,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }

  // Helper to build info rows
  Widget _buildInfoRow(String label, String value, IconData icon,
      [Color? iconColor]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor ?? Colors.grey[600],
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
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
