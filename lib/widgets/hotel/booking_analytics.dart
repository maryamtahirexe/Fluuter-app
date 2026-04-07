import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class BookingAnalyticsWidget extends StatefulWidget {
  const BookingAnalyticsWidget({Key? key}) : super(key: key);

  @override
  _BookingAnalyticsWidgetState createState() => _BookingAnalyticsWidgetState();
}

class _BookingAnalyticsWidgetState extends State<BookingAnalyticsWidget> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _bookings = [];
  Map<String, int> _monthlyBookings = {};
  Map<String, double> _monthlyRevenue = {};
  Map<String, int> _hotelBookings = {};

  // Analytics data
  int _totalBookings = 0;
  double _totalRevenue = 0.0;
  double _averageBookingValue = 0.0;
  int _thisMonthBookings = 0;
  double _thisMonthRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchBookingAnalytics();
  }

  Future<void> _fetchBookingAnalytics() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get user's hotels
      DatabaseEvent userHotelsEvent = await _database
          .child('userHotels')
          .child(currentUser.uid)
          .once();

      List<String> userHotelIds = [];
      Map<String, String> hotelNames = {};

      if (userHotelsEvent.snapshot.exists && userHotelsEvent.snapshot.value != null) {
        Map<String, dynamic> userHotels = Map<String, dynamic>.from(userHotelsEvent.snapshot.value as Map);
        userHotelIds = userHotels.keys.toList();

        // Get hotel names
        for (String hotelId in userHotelIds) {
          DatabaseEvent hotelEvent = await _database.child('hotels').child(hotelId).once();
          if (hotelEvent.snapshot.exists) {
            Map<String, dynamic> hotelData = Map<String, dynamic>.from(hotelEvent.snapshot.value as Map);
            hotelNames[hotelId] = hotelData['name'] ?? 'Unknown Hotel';
          }
        }
      }

      // Fetch all bookings for user's hotels
      DatabaseEvent bookingsEvent = await _database.child('bookings').once();
      List<Map<String, dynamic>> userBookings = [];

      if (bookingsEvent.snapshot.exists && bookingsEvent.snapshot.value != null) {
        Map<String, dynamic> allBookings = Map<String, dynamic>.from(bookingsEvent.snapshot.value as Map);

        for (String bookingId in allBookings.keys) {
          Map<String, dynamic> booking = Map<String, dynamic>.from(allBookings[bookingId]);

          if (userHotelIds.contains(booking['hotelId'])) {
            booking['id'] = bookingId;
            booking['hotelName'] = hotelNames[booking['hotelId']] ?? 'Unknown Hotel';
            userBookings.add(booking);
          }
        }
      }

      _processBookingData(userBookings);

    } catch (e) {
      print('Error fetching booking analytics: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _processBookingData(List<Map<String, dynamic>> bookings) {
    _bookings = bookings;
    _monthlyBookings.clear();
    _monthlyRevenue.clear();
    _hotelBookings.clear();

    _totalBookings = bookings.length;
    _totalRevenue = 0.0;

    DateTime now = DateTime.now();
    String currentMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    _thisMonthBookings = 0;
    _thisMonthRevenue = 0.0;

    for (var booking in bookings) {
      double price = (booking['totalPrice'] ?? 0).toDouble();
      _totalRevenue += price;

      // Process by month
      if (booking['createdAt'] != null) {
        DateTime bookingDate = DateTime.fromMillisecondsSinceEpoch(booking['createdAt']);
        String monthKey = "${bookingDate.year}-${bookingDate.month.toString().padLeft(2, '0')}";

        _monthlyBookings[monthKey] = (_monthlyBookings[monthKey] ?? 0) + 1;
        _monthlyRevenue[monthKey] = (_monthlyRevenue[monthKey] ?? 0.0) + price;

        // Current month data
        if (monthKey == currentMonth) {
          _thisMonthBookings++;
          _thisMonthRevenue += price;
        }
      }

      // Process by hotel
      String hotelName = booking['hotelName'] ?? 'Unknown Hotel';
      _hotelBookings[hotelName] = (_hotelBookings[hotelName] ?? 0) + 1;
    }

    _averageBookingValue = _totalBookings > 0 ? _totalRevenue / _totalBookings : 0.0;
  }

  List<FlSpot> _getMonthlyBookingSpots() {
    List<String> sortedMonths = _monthlyBookings.keys.toList()..sort();
    List<FlSpot> spots = [];

    for (int i = 0; i < sortedMonths.length; i++) {
      String month = sortedMonths[i];
      spots.add(FlSpot(i.toDouble(), (_monthlyBookings[month] ?? 0).toDouble()));
    }

    return spots;
  }

  List<PieChartSectionData> _getHotelBookingSections() {
    List<Color> colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];

    List<PieChartSectionData> sections = [];
    int colorIndex = 0;

    _hotelBookings.entries.forEach((entry) {
      double percentage = (_totalBookings > 0) ? (entry.value / _totalBookings) * 100 : 0;

      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: entry.value.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return sections;
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Center the content
        mainAxisSize: MainAxisSize.min, // Take minimum space needed
        children: [
          Icon(icon, color: color, size: 20), // Reduced icon size
          const SizedBox(height: 4), // Reduced spacing
          Flexible( // Allow text to be flexible
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16, // Reduced font size
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis, // Handle overflow
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2), // Reduced spacing
          Flexible( // Allow text to be flexible
            child: Text(
              title,
              style: TextStyle(
                fontSize: 10, // Reduced font size
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis, // Handle overflow
              maxLines: 2, // Allow 2 lines for title
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading booking analytics...'),
            ],
          ),
        ),
      );
    }

    if (_totalBookings == 0) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Booking Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Analytics will appear here once you receive bookings',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Booking Analytics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Stats Cards - Fixed with better aspect ratio
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.4, // Increased aspect ratio for more height
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildStatCard(
                      'Total Bookings',
                      _totalBookings.toString(),
                      Icons.book,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Total Revenue',
                      '\$${_totalRevenue.toStringAsFixed(0)}',
                      Icons.attach_money,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'This Month',
                      _thisMonthBookings.toString(),
                      Icons.calendar_today,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      'Avg. Value',
                      '\$${_averageBookingValue.toStringAsFixed(0)}',
                      Icons.trending_up,
                      Colors.purple,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Monthly Bookings Chart
                if (_monthlyBookings.isNotEmpty) ...[
                  Text(
                    'Monthly Bookings Trend',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _getMonthlyBookingSpots(),
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.blue.withOpacity(0.1),
                            ),
                            dotData: FlDotData(show: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Hotel Bookings Distribution
                if (_hotelBookings.isNotEmpty) ...[
                  Text(
                    'Bookings by Hotel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: PieChart(
                            PieChartData(
                              sections: _getHotelBookingSections(),
                              centerSpaceRadius: 40,
                              sectionsSpace: 2,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _hotelBookings.entries.map((entry) {
                              int index = _hotelBookings.keys.toList().indexOf(entry.key);
                              Color color = [
                                Colors.blue,
                                Colors.orange,
                                Colors.green,
                                Colors.red,
                                Colors.purple,
                                Colors.teal,
                                Colors.amber,
                                Colors.indigo,
                              ][index % 8];

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${entry.key.length > 15 ? entry.key.substring(0, 15)+'...' : entry.key} (${entry.value})',
                                        style: const TextStyle(fontSize: 10),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}