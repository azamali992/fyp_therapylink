// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:therapylink/Views/custom_app_bar.dart';
import 'package:therapylink/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

class MoodAnalysisPage extends StatefulWidget {
  const MoodAnalysisPage({super.key});

  @override
  State<MoodAnalysisPage> createState() => _MoodAnalysisPageState();
}

class _MoodAnalysisPageState extends State<MoodAnalysisPage>
    with SingleTickerProviderStateMixin {
  final List<String> timeFrames = ['Week', 'Month', 'Year'];
  String selectedTimeFrame = 'Week';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Data storage for sentiment analytics
  Map<String, int> _sentimentDistribution = {
    'pos': 0,
    'neg': 0,
    'neu': 0,
  };

  // For line chart data by day
  List<FlSpot> _weeklySpots = [];
  List<FlSpot> _monthlySpots = [];
  List<FlSpot> _yearlySpots = [];

  // Loading state
  bool _isLoading = true;
  String _error = '';

  // Stream subscription for real-time updates
  Stream<QuerySnapshot>? _sentimentStream;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _setupSentimentStream();
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning to this page
    if (!_isLoading && _error.isEmpty) {
      _loadSentimentData();
    }
  }

  // Setup real-time stream for sentiment data
  void _setupSentimentStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print("Setting up sentiment stream for user: ${user.uid}");
      _sentimentStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sentiments')
          .orderBy('timestamp', descending: true)
          .limit(20) // Limit to last 20 for better performance
          .snapshots();

      // Initial load
      _loadSentimentData();
    } else {
      setState(() {
        _isLoading = false;
        _error = 'User not logged in';
      });
    }
  }

  // Fetch sentiment data from Firestore
  Future<void> _loadSentimentData() async {
    if (_sentimentStream == null) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _error = 'User not logged in';
        });
        return;
      }

      // Get current date info for filtering
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));
      final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
      final oneYearAgo = DateTime(now.year - 1, now.month, now.day);

      // Get all sentiments from user's collection
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sentiments')
          .orderBy('timestamp', descending: false)
          .get();

      await _processSentimentData(
          querySnapshot.docs, oneWeekAgo, oneMonthAgo, oneYearAgo);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error loading data: $e';
      });
    }
  }

  Future<void> _processSentimentData(List<QueryDocumentSnapshot> docs,
      DateTime oneWeekAgo, DateTime oneMonthAgo, DateTime oneYearAgo) async {
    // Reset counts
    final distribution = {
      'pos': 0,
      'neg': 0,
      'neu': 0,
    };

    // Data points for each time period
    final weeklyData = <DateTime, List<double>>{};
    final monthlyData = <DateTime, List<double>>{};
    final yearlyData = <DateTime, List<double>>{};

    // Process all documents
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final sentiment = data['sentiment'] as String;
      final timestamp = data['timestamp'] as Timestamp?;

      if (timestamp != null) {
        final date = timestamp.toDate();

        // Update overall distribution regardless of date
        final normalizedSentiment = sentiment.toLowerCase();
        if (distribution.containsKey(normalizedSentiment)) {
          distribution[normalizedSentiment] =
              (distribution[normalizedSentiment] ?? 0) + 1;
        }

        // Calculate sentiment score: positive=5, neutral=3, negative=1
        double sentimentScore = 3.0; // Default neutral
        if (normalizedSentiment == 'pos' || normalizedSentiment == 'positive')
          sentimentScore = 5.0;
        if (normalizedSentiment == 'neg' || normalizedSentiment == 'negative')
          sentimentScore = 1.0;

        // Group by day for weekly data
        if (date.isAfter(oneWeekAgo)) {
          final day = DateTime(date.year, date.month, date.day);
          if (!weeklyData.containsKey(day)) {
            weeklyData[day] = [0, 0]; // [sum, count]
          }
          weeklyData[day]![0] += sentimentScore;
          weeklyData[day]![1] += 1;
        }

        // Group by week for monthly data
        if (date.isAfter(oneMonthAgo)) {
          // Get week number within month
          final weekNumber = (date.day / 7).ceil();
          final weekStart =
              DateTime(date.year, date.month, (weekNumber - 1) * 7 + 1);
          if (!monthlyData.containsKey(weekStart)) {
            monthlyData[weekStart] = [0, 0]; // [sum, count]
          }
          monthlyData[weekStart]![0] += sentimentScore;
          monthlyData[weekStart]![1] += 1;
        }

        // Group by month for yearly data
        if (date.isAfter(oneYearAgo)) {
          final month = DateTime(date.year, date.month, 1);
          if (!yearlyData.containsKey(month)) {
            yearlyData[month] = [0, 0]; // [sum, count]
          }
          yearlyData[month]![0] += sentimentScore;
          yearlyData[month]![1] += 1;
        }
      }
    }

    // Convert grouped data to chart spots
    List<FlSpot> weekSpots = _processTimeData(weeklyData, 7);
    List<FlSpot> monthSpots = _processTimeData(monthlyData, 4);
    List<FlSpot> yearSpots = _processTimeData(yearlyData, 12);

    setState(() {
      _sentimentDistribution = distribution;
      _weeklySpots = weekSpots;
      _monthlySpots = monthSpots;
      _yearlySpots = yearSpots;
      _isLoading = false;
    });
  }

  // Process time-based data into chart spots
  List<FlSpot> _processTimeData(
      Map<DateTime, List<double>> data, int maxPoints) {
    if (data.isEmpty) {
      // Return default data if no real data exists
      return List.generate(maxPoints, (i) => FlSpot(i.toDouble(), 3.0));
    }

    // Sort dates
    final sortedDates = data.keys.toList()..sort();

    // Create spots with evenly distributed X values
    final spots = <FlSpot>[];
    for (var i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final values = data[date]!;
      // Calculate average sentiment for this time period
      final avgSentiment = values[0] / values[1];
      spots.add(FlSpot(i.toDouble(), avgSentiment));
    }

    // If we have fewer points than maxPoints, pad with the last value
    if (spots.length < maxPoints) {
      final lastValue = spots.isNotEmpty ? spots.last.y : 3.0;
      for (var i = spots.length; i < maxPoints; i++) {
        spots.add(FlSpot(i.toDouble(), lastValue));
      }
    }

    return spots;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar:
          CustomAppBar(screenWidth: screenWidth, screenHeight: screenHeight),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.backgroundGradientStart,
              Color.fromARGB(255, 55, 13, 104),
              AppColors.backgroundGradientEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.06,
              vertical: screenHeight * 0.02,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingIndicator();
    } else if (_error.isNotEmpty) {
      return _buildErrorWidget();
    } else {
      return RefreshIndicator(
        onRefresh: _loadSentimentData,
        color: Colors.white,
        backgroundColor: AppColors.backgroundGradientStart,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Mood Analysis',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Track and understand your emotional patterns',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              _buildOverallMoodCard(),
              const SizedBox(height: 24),
              _buildMoodTrendCard(),
              const SizedBox(height: 24),
              _buildSentimentHistoryCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text('Loading your mood data...',
              style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(_error, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadSentimentData,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallMoodCard() {
    final total = _sentimentDistribution.values.fold(0, (a, b) => a + b);

    // Ensure we have some data to display
    final hasData = total > 0;

    // Calculate percentages for each sentiment
    final posPercentage =
        hasData ? (_sentimentDistribution['pos'] ?? 0) / total * 100 : 33.3;
    final neuPercentage =
        hasData ? (_sentimentDistribution['neu'] ?? 0) / total * 100 : 33.3;
    final negPercentage =
        hasData ? (_sentimentDistribution['neg'] ?? 0) / total * 100 : 33.3;

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.pie_chart_outline,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Overall Mood Distribution',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasData
                ? 'Based on $total recorded emotions'
                : 'No mood data available yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1500),
              tween: Tween<double>(begin: 0, end: 1),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: posPercentage * value,
                        title: 'Positive\n${posPercentage.toStringAsFixed(1)}%',
                        color: Colors.green.withOpacity(0.8),
                        radius: 60,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      PieChartSectionData(
                        value: neuPercentage * value,
                        title: 'Neutral\n${neuPercentage.toStringAsFixed(1)}%',
                        color: Colors.blue.withOpacity(0.8),
                        radius: 60,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      PieChartSectionData(
                        value: negPercentage * value,
                        title: 'Negative\n${negPercentage.toStringAsFixed(1)}%',
                        color: Colors.red.withOpacity(0.8),
                        radius: 60,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    centerSpaceColor: Colors.black.withOpacity(0.2),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (hasData)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatItem(
                    'Positive',
                    '${_sentimentDistribution['pos'] ?? 0}',
                    Icons.sentiment_very_satisfied,
                    Colors.green),
                _buildStatItem(
                    'Neutral',
                    '${_sentimentDistribution['neu'] ?? 0}',
                    Icons.sentiment_neutral,
                    Colors.blue),
                _buildStatItem(
                    'Negative',
                    '${_sentimentDistribution['neg'] ?? 0}',
                    Icons.sentiment_very_dissatisfied,
                    Colors.red),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getCurrentTimeFrameData() {
    switch (selectedTimeFrame) {
      case 'Week':
        return _weeklySpots;
      case 'Month':
        return _monthlySpots;
      case 'Year':
        return _yearlySpots;
      default:
        return _weeklySpots;
    }
  }

  List<String> _getTimeLabels() {
    switch (selectedTimeFrame) {
      case 'Week':
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      case 'Month':
        return ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
      case 'Year':
        return [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
      default:
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    }
  }

  Widget _buildMoodTrendCard() {
    final spots = _getCurrentTimeFrameData();
    final labels = _getTimeLabels();
    final maxX = spots.isEmpty ? 6.0 : (spots.length - 1).toDouble();

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.show_chart,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                'Mood Trends',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedTimeFrame,
                    dropdownColor:
                        AppColors.backgroundGradientStart.withOpacity(0.9),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: Colors.white, size: 20),
                    items: timeFrames.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedTimeFrame = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your emotional journey over time',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1800),
              tween: Tween<double>(begin: 0, end: 1),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.white.withOpacity(0.1),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: Colors.white.withOpacity(0.1),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= labels.length) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              labels[index],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            String mood = '';
                            if (value == 1) mood = 'Neg';
                            if (value == 3) mood = 'Neu';
                            if (value == 5) mood = 'Pos';

                            if (mood.isEmpty) return const SizedBox.shrink();

                            return Text(
                              mood,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: maxX,
                    minY: 0,
                    maxY: 6,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots
                            .map((spot) => FlSpot(spot.x, spot.y * value))
                            .toList(),
                        isCurved: true,
                        gradient: const LinearGradient(
                          colors: [
                            Colors.greenAccent,
                            Colors.lightBlue,
                          ],
                        ),
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            // Color based on sentiment value
                            Color dotColor = Colors.blue;
                            if (spot.y > 4) {
                              dotColor = Colors.green;
                            } else if (spot.y < 2) {
                              dotColor = Colors.red;
                            }

                            return FlDotCirclePainter(
                              radius: 6,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: dotColor,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.greenAccent.withOpacity(0.3 * value),
                              Colors.lightBlue.withOpacity(0.1 * value),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMoodLegendItem('Positive (5)', Colors.green),
              _buildMoodLegendItem('Neutral (3)', Colors.blue),
              _buildMoodLegendItem('Negative (1)', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Reusable glass card widget
  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: -5,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSentimentHistoryCard() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.history,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Sentiment History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your recent emotional responses',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          if (_sentimentStream != null)
            StreamBuilder<QuerySnapshot>(
              stream: _sentimentStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading sentiment history: ${snapshot.error}',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isNotEmpty) {
                  // Debug print to see what sentiments are being retrieved
                  print("Retrieved ${docs.length} sentiment records");
                  print("Sample sentiments: ${docs.take(3).map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['sentiment'];
                  }).toList()}");
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'No sentiment history available yet',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                    ),
                  );
                }

                // Convert documents to a list of sentiment history items
                return ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: docs.length > 10 ? 10 : docs.length,
                  itemBuilder: (context, index) {
                    final item = docs[index].data() as Map<String, dynamic>;
                    return _buildSentimentHistoryItem(
                      text: item['text'] ?? 'No text',
                      sentiment: item['sentiment'] ?? 'neu',
                      timestamp: item['timestamp'] as Timestamp?,
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSentimentHistoryItem({
    required String text,
    required String sentiment,
    Timestamp? timestamp,
  }) {
    // Normalize sentiment to lowercase for case-insensitive comparison
    final normalizedSentiment = sentiment.toLowerCase();

    // Get sentiment color and emoji
    final Color color =
        normalizedSentiment == 'pos' || normalizedSentiment == 'positive'
            ? Colors.green
            : normalizedSentiment == 'neg' || normalizedSentiment == 'negative'
                ? Colors.red
                : Colors.blue;

    final String emoji =
        normalizedSentiment == 'pos' || normalizedSentiment == 'positive'
            ? '😊'
            : normalizedSentiment == 'neg' || normalizedSentiment == 'negative'
                ? '😢'
                : '😐';

    final String sentimentText =
        normalizedSentiment == 'pos' || normalizedSentiment == 'positive'
            ? 'Positive'
            : normalizedSentiment == 'neg' || normalizedSentiment == 'negative'
                ? 'Negative'
                : 'Neutral';

    // Format timestamp
    String timeString = 'Unknown time';
    if (timestamp != null) {
      final date = timestamp.toDate();
      timeString = DateFormat('MMM d, yyyy • h:mm a').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sentimentText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeString,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                gradient: RadialGradient(
                  colors: [
                    color.withOpacity(0.5),
                    color.withOpacity(0.2),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  normalizedSentiment == 'pos' ||
                          normalizedSentiment == 'positive'
                      ? '++'
                      : normalizedSentiment == 'neg' ||
                              normalizedSentiment == 'negative'
                          ? '--'
                          : '~',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
