import 'package:firebase/widgets/hotel/book_hotel.dart';
import 'package:firebase/widgets/hotel/hotel_reviews_list.dart';
import 'package:firebase/widgets/hotel/review_hotel.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/hotel.dart';

class HotelDetailScreen extends StatefulWidget {
  final String hotelId;

  const HotelDetailScreen({Key? key, required this.hotelId}) : super(key: key);

  @override
  _HotelDetailScreenState createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends State<HotelDetailScreen> {
  late Future<Hotel?> _hotelFuture;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PageController _pageController = PageController();

  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _hotelFuture = _fetchHotelDetails();
  }

  Future<Hotel?> _fetchHotelDetails() async {
    try {
      DatabaseEvent event = await _database.child('hotels').child(widget.hotelId).once();

      if (!event.snapshot.exists || event.snapshot.value == null) {
        return null;
      }

      Map<String, dynamic> hotelData = Map<String, dynamic>.from(event.snapshot.value as Map);
      return Hotel.fromFirebaseJson(hotelData);
    } catch (e) {
      print('Error fetching hotel details: $e');
      throw Exception('Failed to fetch hotel details: $e');
    }
  }

  bool _isOwner(Hotel hotel) {
    User? currentUser = _auth.currentUser;
    return currentUser != null && currentUser.uid == hotel.ownerId;
  }

  Future<void> _deleteHotel(Hotel hotel) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete'),
          content: Text('Are you sure you want to delete "${hotel.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _database.child('hotels').child(widget.hotelId).remove();
        _showSnackBar('Hotel deleted successfully', Colors.green);
        Navigator.of(context).pop();
      } catch (e) {
        _showSnackBar('Failed to delete hotel: $e', Colors.red);
      }
    }
  }

  void _editHotel(Hotel hotel) {
    // Navigate to edit hotel screen
    Navigator.pushNamed(
      context,
      '/edit-hotel',
      arguments: hotel,
    ).then((_) {
      // Refresh hotel details after edit
      setState(() {
        _hotelFuture = _fetchHotelDetails();
      });
    });
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

  void _onBookingSuccess() {
    // You can add any additional logic here after a successful booking
    // For example, refresh hotel data or show additional confirmation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Hotel?>(
        future: _hotelFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading hotel details...'),
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
                    onPressed: () {
                      setState(() {
                        _hotelFuture = _fetchHotelDetails();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hotel_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Hotel not found'),
                ],
              ),
            );
          }

          final hotel = snapshot.data!;
          final isOwner = _isOwner(hotel);

          return CustomScrollView(
            slivers: [
              // App Bar with Images
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: hotel.imageUrls != null && hotel.imageUrls!.isNotEmpty
                      ? PageView.builder(
                    controller: _pageController,
                    itemCount: hotel.imageUrls!.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        hotel.imageUrls![index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image_not_supported, size: 50),
                          );
                        },
                      );
                    },
                  )
                      : Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.hotel, size: 100, color: Colors.grey),
                  ),
                ),
                actions: [
                  if (isOwner) ...[
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editHotel(hotel),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteHotel(hotel),
                    ),
                  ],
                ],
              ),

              // Hotel Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image indicators
                      if (hotel.imageUrls != null && hotel.imageUrls!.length > 1)
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              hotel.imageUrls!.length,
                                  (index) => Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index == _currentImageIndex
                                      ? Colors.blue
                                      : Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              hotel.name ?? 'Unknown Hotel',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Location
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            hotel.location,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Hotel Type
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          hotel.type ?? 'Hotel',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Price
                      Row(
                        children: [
                          Text(
                            '\$${hotel.pricePerNight?.toStringAsFixed(2) ?? '0.00'}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Text(
                            ' / night',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Capacity
                      Row(
                        children: [
                          const Icon(Icons.people, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'Up to ${hotel.adultCapacity ?? 0} adults, ${hotel.childCapacity ?? 0} children',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      if (hotel.description != null && hotel.description!.isNotEmpty) ...[
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hotel.description!,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Facilities
                      if (hotel.facilities != null && hotel.facilities!.isNotEmpty) ...[
                        const Text(
                          'Facilities',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: hotel.facilities!.map((facility) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                facility,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Booking Section (only for non-owners)
                      if (!isOwner) ...[
                        HotelBookingWidget(
                          hotel: hotel,
                          onBookingSuccess: _onBookingSuccess,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Owner Section
                      if (isOwner) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.verified_user, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    'You own this hotel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _editHotel(hotel),
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _deleteHotel(hotel),
                                      icon: const Icon(Icons.delete),
                                      label: const Text('Delete'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Reviews Section
                      HotelReviewsWidget(hotelId: widget.hotelId),
                      HotelReviewsListWidget(hotelId: widget.hotelId)
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}