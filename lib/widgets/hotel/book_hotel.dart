import 'package:firebase/models/hotel.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HotelBookingWidget extends StatefulWidget {
  final Hotel hotel;
  final VoidCallback? onBookingSuccess;

  const HotelBookingWidget({
    Key? key,
    required this.hotel,
    this.onBookingSuccess,
  }) : super(key: key);

  @override
  _HotelBookingWidgetState createState() => _HotelBookingWidgetState();
}

class _HotelBookingWidgetState extends State<HotelBookingWidget> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime _checkInDate = DateTime.now();
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 1));
  int _adults = 1;
  int _children = 0;

  Future<void> _selectCheckInDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _checkInDate) {
      setState(() {
        _checkInDate = picked;
        if (_checkOutDate.isBefore(_checkInDate.add(const Duration(days: 1)))) {
          _checkOutDate = _checkInDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectCheckOutDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkOutDate,
      firstDate: _checkInDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _checkOutDate) {
      setState(() {
        _checkOutDate = picked;
      });
    }
  }

  int _calculateNights() {
    return _checkOutDate.difference(_checkInDate).inDays;
  }

  double _calculateTotalPrice() {
    return (widget.hotel.pricePerNight ?? 0) * _calculateNights();
  }

  Future<void> _bookHotel() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      _showSnackBar('Please log in to book a hotel', Colors.red);
      return;
    }

    if (_adults > (widget.hotel.adultCapacity ?? 0) ||
        _children > (widget.hotel.childCapacity ?? 0)) {
      _showSnackBar('Guest capacity exceeded', Colors.red);
      return;
    }

    try {
      // Create booking data
      Map<String, dynamic> bookingData = {
        'id': _database.child('bookings').push().key,
        'hotelId': widget.hotel.id,
        'hotelName': widget.hotel.name,
        'userId': currentUser.uid,
        'userEmail': currentUser.email,
        'checkInDate': _checkInDate.millisecondsSinceEpoch,
        'checkOutDate': _checkOutDate.millisecondsSinceEpoch,
        'adults': _adults,
        'children': _children,
        'totalPrice': _calculateTotalPrice(),
        'nights': _calculateNights(),
        'status': 'confirmed',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Save booking to Firebase
      await _database.child('bookings').child(bookingData['id']).set(bookingData);

      _showSnackBar('Hotel booked successfully!', Colors.green);

      // Show booking confirmation dialog
      _showBookingConfirmationDialog(bookingData);

      // Call success callback
      if (widget.onBookingSuccess != null) {
        widget.onBookingSuccess!();
      }
    } catch (e) {
      _showSnackBar('Failed to book hotel: $e', Colors.red);
    }
  }

  void _showBookingConfirmationDialog(Map<String, dynamic> bookingData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Expanded( // Wrap Text in Expanded to prevent overflow
                child: Text('Booking Confirmed'),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite, // Ensure dialog uses maximum available width
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hotel: ${widget.hotel.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis, // Handle long hotel names
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Text(
                  'Check-in: ${_formatDate(_checkInDate)}',
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Check-out: ${_formatDate(_checkOutDate)}',
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Guests: $_adults adults, $_children children',
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Nights: ${_calculateNights()}',
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: \$${_calculateTotalPrice().toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
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

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Book Your Stay',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Date Selection
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _selectCheckInDate,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Check-in',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(_formatDate(_checkInDate),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: _selectCheckOutDate,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Check-out',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(_formatDate(_checkOutDate),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Guest Selection
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Adults', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _adults > 1 ? () => setState(() => _adults--) : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Text('$_adults',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          onPressed: _adults < (widget.hotel.adultCapacity ?? 0)
                              ? () => setState(() => _adults++)
                              : null,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Children', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _children > 0 ? () => setState(() => _children--) : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Text('$_children',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          onPressed: _children < (widget.hotel.childCapacity ?? 0)
                              ? () => setState(() => _children++)
                              : null,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total Price
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_calculateNights()} nights'),
                    Text(
                      'Total: \$${_calculateTotalPrice().toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Book Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _bookHotel,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Book Now',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}