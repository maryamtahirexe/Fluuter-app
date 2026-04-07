import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _myBookings = [];
  List<Map<String, dynamic>> _receivedBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch all bookings
      DatabaseEvent bookingsEvent = await _database.child('bookings').once();

      // Fetch user's hotels to identify received bookings
      DatabaseEvent userHotelsEvent = await _database.child('userHotels').child(currentUser.uid).once();

      List<String> userHotelIds = [];
      if (userHotelsEvent.snapshot.exists && userHotelsEvent.snapshot.value != null) {
        Map<String, dynamic> userHotels = Map<String, dynamic>.from(userHotelsEvent.snapshot.value as Map);
        userHotelIds = userHotels.keys.toList();
      }

      List<Map<String, dynamic>> myBookings = [];
      List<Map<String, dynamic>> receivedBookings = [];

      if (bookingsEvent.snapshot.exists && bookingsEvent.snapshot.value != null) {
        Map<String, dynamic> allBookings = Map<String, dynamic>.from(bookingsEvent.snapshot.value as Map);

        for (String bookingId in allBookings.keys) {
          Map<String, dynamic> booking = Map<String, dynamic>.from(allBookings[bookingId]);
          booking['id'] = bookingId;

          // Check if this is user's booking (they made this booking)
          if (booking['userId'] == currentUser.uid) {
            myBookings.add(booking);
          }
          // Check if this is a booking for user's hotel (they received this booking)
          else if (userHotelIds.contains(booking['hotelId'])) {
            receivedBookings.add(booking);
          }
        }
      }

      // Sort bookings by creation date (newest first)
      myBookings.sort((a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0));
      receivedBookings.sort((a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0));

      setState(() {
        _myBookings = myBookings;
        _receivedBookings = receivedBookings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching bookings: $e');
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error fetching bookings: $e', Colors.red);
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: const Text('Are you sure you want to cancel this booking?'),
          actions: [
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Yes', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _database.child('bookings').child(bookingId).update({
          'status': 'cancelled',
          'cancelledAt': DateTime.now().millisecondsSinceEpoch,
        });
        _showSnackBar('Booking cancelled successfully', Colors.green);
        _fetchBookings(); // Refresh the list
      } catch (e) {
        _showSnackBar('Failed to cancel booking: $e', Colors.red);
      }
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      await _database.child('bookings').child(bookingId).update({
        'status': status,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      _showSnackBar('Booking $status successfully', Colors.green);
      _fetchBookings(); // Refresh the list
    } catch (e) {
      _showSnackBar('Failed to update booking: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
    }
  }

  String _formatDate(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, bool isReceived) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotel Name and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking['hotelName'] ?? 'Unknown Hotel',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Guest/Customer Info
            if (isReceived) ...[
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Guest: ${booking['userEmail'] ?? 'Unknown'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Check-in and Check-out dates
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Check-in', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        _formatDate(booking['checkInDate'] ?? 0),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.grey),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Check-out', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        _formatDate(booking['checkOutDate'] ?? 0),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Guests and Duration
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Guests: ${booking['adults'] ?? 0} adults, ${booking['children'] ?? 0} children',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  '${booking['nights'] ?? 0} nights',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Total Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: \$${(booking['totalPrice'] ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'Booked: ${_formatDate(booking['createdAt'] ?? 0)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                if (!isReceived && booking['status'] == 'confirmed') ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _cancelBooking(booking['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ] else if (isReceived && booking['status'] == 'confirmed') ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateBookingStatus(booking['id'], 'completed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Mark Complete'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateBookingStatus(booking['id'], 'cancelled'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.flight_takeoff),
              text: 'My Bookings (${_myBookings.length})',
            ),
            Tab(
              icon: const Icon(Icons.business),
              text: 'Received (${_receivedBookings.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading bookings...'),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchBookings,
        child: TabBarView(
          controller: _tabController,
          children: [
            // My Bookings Tab
            _myBookings.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No bookings yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start exploring hotels to make your first booking!',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _myBookings.length,
              itemBuilder: (context, index) => _buildBookingCard(_myBookings[index], false),
            ),

            // Received Bookings Tab
            _receivedBookings.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hotel_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No bookings received',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your hotels haven\'t received any bookings yet.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _receivedBookings.length,
              itemBuilder: (context, index) => _buildBookingCard(_receivedBookings[index], true),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}