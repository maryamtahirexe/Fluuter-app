import 'package:firebase/widgets/hotel/booking_analytics.dart';
import 'package:firebase/widgets/hotel_card.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/hotel.dart';
import 'package:fl_chart/fl_chart.dart';

class MyHotelsScreen extends StatefulWidget {
  @override
  _MyHotelsScreenState createState() => _MyHotelsScreenState();
}

class _MyHotelsScreenState extends State<MyHotelsScreen> {
  late Future<List<Hotel>> _hotelListFuture;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _showActiveOnly = true;

  @override
  void initState() {
    super.initState();
    _hotelListFuture = _fetchHotelsByOwner();
  }

  // Alternative method: Fetch hotels directly by owner ID (more efficient)
  Future<List<Hotel>> _fetchHotelsByOwner() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      print(currentUser);
      List<Hotel> hotels = [];

      // Query hotels by ownerId
      DatabaseEvent event = await _database
          .child('hotels')
          .orderByChild('ownerId')
          .equalTo(currentUser.uid)
          .once();

      if (!event.snapshot.exists || event.snapshot.value == null) {
        return hotels;
      }

      final data = event.snapshot.value as Map;
      Map<String, dynamic> hotelsData = Map<String, dynamic>.from(data);

      for (String hotelId in hotelsData.keys) {
        Map<String, dynamic> hotelData =
        Map<String, dynamic>.from(hotelsData[hotelId]);
        print(hotelData);
        // Helper function to safely convert to int
        int safeInt(dynamic value, int defaultValue) {
          if (value == null) return defaultValue;
          if (value is int) return value;
          if (value is double) return value.toInt();
          if (value is String) return int.tryParse(value) ?? defaultValue;
          return defaultValue;
        }

        // Helper function to safely convert to double
        double safeDouble(dynamic value, double defaultValue) {
          if (value == null) return defaultValue;
          if (value is double) return value;
          if (value is int) return value.toDouble();
          if (value is String) return double.tryParse(value) ?? defaultValue;
          return defaultValue;
        }

        Hotel hotel = Hotel.fromFirebaseJson(hotelData);


        // Filter by active status if needed
        if (!_showActiveOnly || hotel.isActive!) {
          hotels.add(hotel);
        }
      }

      // Sort hotels by creation date (newest first)
      hotels.sort((a, b) {
        // Handle timestamp sorting more safely
        int aTime = 0;
        int bTime = 0;

        if (a.createdAt != null) {
          if (a.createdAt is int) {
            aTime = a.createdAt as int;
          } else if (a.createdAt is double) {
            aTime = (a.createdAt as double).toInt();
          }
        }

        if (b.createdAt != null) {
          if (b.createdAt is int) {
            bTime = b.createdAt as int;
          } else if (b.createdAt is double) {
            bTime = (b.createdAt as double).toInt();
          }
        }

        return bTime.compareTo(aTime);
      });

      return hotels;

    } catch (e) {
      print('Error fetching hotels by owner: $e');
      throw Exception('Failed to fetch hotels: $e');
    }
  }

  void _refreshHotels() {
    setState(() {
      _hotelListFuture = _fetchHotelsByOwner(); // Using the more efficient method
    });
  }

  void _toggleFilter() {
    setState(() {
      _showActiveOnly = !_showActiveOnly;
      _refreshHotels();
    });
  }

  Future<void> _showDeleteAllDialog() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete All Hotels'),
          content: const Text(
            'Are you sure you want to delete ALL your hotels? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete All', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // Get user's hotel list
        DatabaseEvent event = await _database
            .child('userHotels')
            .child(currentUser.uid)
            .once();

        if (event.snapshot.exists) {
          Map<String, dynamic> userHotels =
          Map<String, dynamic>.from(event.snapshot.value as Map);

          // Delete each hotel
          for (String hotelId in userHotels.keys) {
            await _database.child('hotels').child(hotelId).remove();
          }

          // Clear user's hotel list
          await _database.child('userHotels').child(currentUser.uid).remove();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('All hotels deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _refreshHotels();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete hotels: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        title: Text(
          "My Hotels",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: Colors.blue,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showActiveOnly ? Icons.visibility : Icons.visibility_off,
              color: Colors.blue,
            ),
            onPressed: _toggleFilter,
            tooltip: _showActiveOnly ? 'Show All Hotels' : 'Show Active Only',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'refresh') {
                _refreshHotels();
              } else if (value == 'delete_all') {
                _showDeleteAllDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete All Hotels'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshHotels();
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Filter indicator
              if (!_showActiveOnly)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Showing all hotels (including inactive)',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Hotels list
              Expanded(
                child: FutureBuilder<List<Hotel>>(
                  future: _hotelListFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading your hotels...'),
                          ],
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refreshHotels,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.hotel_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _showActiveOnly
                                  ? 'No active hotels found'
                                  : 'No hotels found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add your first hotel to get started!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to add hotel screen
                                Navigator.pushNamed(context, '/add-hotel')
                                    .then((_) => _refreshHotels());
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Hotel'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      final hotels = snapshot.data!;
                      return Column(
                        children: [
                          // Hotels count
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  '${hotels.length} hotel${hotels.length != 1 ? 's' : ''} found',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                if (hotels.isNotEmpty)
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/add-hotel')
                                          .then((_) => _refreshHotels());
                                    },
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Add More'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Hotels list
                          Expanded(
                            child: Column(
                              children: [
                                // Hotels count and add button (existing code)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${hotels.length} hotel${hotels.length != 1 ? 's' : ''} found',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (hotels.isNotEmpty)
                                        TextButton.icon(
                                          onPressed: () {
                                            Navigator.pushNamed(context, '/add-hotel')
                                                .then((_) => _refreshHotels());
                                          },
                                          icon: const Icon(Icons.add, size: 16),
                                          label: const Text('Add More'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.blue,
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Hotels list
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: hotels.length + 1, // +1 for the analytics widget
                                    itemBuilder: (context, index) {
                                      // Show hotels first
                                      if (index < hotels.length) {
                                        final hotel = hotels[index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: HotelCard(
                                            hotel: hotel,
                                            onTap: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/hotel-details',
                                                arguments: hotel.id,
                                              ).then((_) => _refreshHotels());
                                            },
                                            onDelete: () {
                                              _refreshHotels();
                                            },
                                          ),
                                        );
                                      }
                                      // Show analytics widget at the end
                                      else {
                                        return const BookingAnalyticsWidget();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-hotel')
              .then((_) => _refreshHotels());
        },
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Add New Hotel',
      ),
    );
  }
}