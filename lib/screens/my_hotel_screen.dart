import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/hotel.dart';
import '../widgets/hotel/info_card.dart';
import '../widgets/hotel/facilities_grid.dart';

class MyHotelScreen extends StatefulWidget {
  final String hotelId;

  const MyHotelScreen({super.key, required this.hotelId});

  @override
  _MyHotelScreenState createState() => _MyHotelScreenState();
}

class _MyHotelScreenState extends State<MyHotelScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Hotel> _fetchHotelData() async {
    try {
      // Get current user to verify ownership (optional)
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("User not authenticated");
      }

      // Fetch hotel data from Firebase Realtime Database
      DatabaseEvent event = await _database
          .child('hotels')
          .child(widget.hotelId)
          .once();

      if (!event.snapshot.exists) {
        throw Exception("Hotel not found");
      }

      Map<String, dynamic> hotelData =
      Map<String, dynamic>.from(event.snapshot.value as Map);

      // Convert Firebase data to Hotel model
      return Hotel(
        id: hotelData['id'] ?? widget.hotelId,
        name: hotelData['name'] ?? '',
        city: hotelData['city'] ?? '',
        country: hotelData['country'] ?? '',
        description: hotelData['description'] ?? '',
        type: hotelData['type'] ?? 'Hotel',
        pricePerNight: (hotelData['pricePerNight'] ?? 0).toDouble(),
        adultCapacity: hotelData['adultCapacity'] ?? 0,
        childCapacity: hotelData['childCapacity'] ?? 0,
        facilities: List<String>.from(hotelData['facilities'] ?? []),
        imageUrls: List<String>.from(hotelData['imageUrls'] ?? []),
        ownerId: hotelData['ownerId'] ?? '',
        ownerEmail: hotelData['ownerEmail'] ?? '',
        isActive: hotelData['isActive'] ?? true,
        createdAt: hotelData['createdAt'],
        updatedAt: hotelData['updatedAt'],
      );

    } catch (e) {
      print('Error fetching hotel data: $e');
      throw Exception('Failed to fetch hotel data: $e');
    }
  }

  Future<void> _deleteHotel() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("User not authenticated");
      }

      // Show confirmation dialog
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete Hotel'),
            content: const Text('Are you sure you want to delete this hotel? This action cannot be undone.'),
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
        // Delete from hotels collection
        await _database.child('hotels').child(widget.hotelId).remove();

        // Delete from user's hotels list
        await _database
            .child('userHotels')
            .child(currentUser.uid)
            .child(widget.hotelId)
            .remove();

        // Show success message and navigate back
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hotel deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      print('Error deleting hotel: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete hotel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleHotelStatus(bool currentStatus) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("User not authenticated");
      }

      // Update hotel status
      await _database
          .child('hotels')
          .child(widget.hotelId)
          .update({
        'isActive': !currentStatus,
        'updatedAt': ServerValue.timestamp,
      });

      // Refresh the screen
      setState(() {});

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentStatus ? 'Hotel deactivated' : 'Hotel activated',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating hotel status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update hotel status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel Details'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                // Navigate to edit screen (you'll need to implement this)
                // Navigator.push(context, MaterialPageRoute(
                //   builder: (context) => EditHotelScreen(hotelId: widget.hotelId),
                // ));
              } else if (value == 'delete') {
                await _deleteHotel();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Edit Hotel'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Hotel'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<Hotel>(
        future: _fetchHotelData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final hotel = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Carousel/Gallery
                Stack(
                  children: [
                    SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: hotel.imageUrls!.isNotEmpty
                          ? PageView.builder(
                        itemCount: hotel.imageUrls?.length,
                        itemBuilder: (context, index) {
                          return Image.network(
                            hotel.imageUrls![index],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.image_not_supported, size: 50),
                                ),
                              );
                            },
                          );
                        },
                      )
                          : Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.hotel, size: 50, color: Colors.grey),
                        ),
                      ),
                    ),
                    // Price Badge
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '\$${hotel.pricePerNight?.toStringAsFixed(0)} / night',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    // Status Badge
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: hotel.isActive! ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          hotel.isActive! ? 'Active' : 'Inactive',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    // Image Counter (if multiple images)
                    if ( hotel.imageUrls!.length > 1)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '1/${hotel.imageUrls!.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hotel Name and Rating
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              hotel.name!,
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Location
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.blue, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${hotel.city}, ${hotel.country}',
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 32),

                      // Quick Info Cards
                      Row(
                        children: [
                          Expanded(
                            child: InfoCard(
                              icon: Icons.hotel,
                              title: 'Type',
                              value: hotel.type!,
                            ),
                          ),
                          Expanded(
                            child: InfoCard(
                              icon: Icons.person,
                              title: 'Capacity',
                              value: '${hotel.adultCapacity} Adults, ${hotel.childCapacity} Children',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Description Section
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
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Facilities Section
                      Row(
                        children: [
                          const Icon(Icons.wifi, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Facilities',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FacilitiesGrid(facilities: hotel.facilities!),
                      const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _toggleHotelStatus(hotel.isActive!),
                              icon: Icon(
                                hotel.isActive! ? Icons.visibility_off : Icons.visibility,
                              ),
                              label: Text(
                                hotel.isActive! ? 'Deactivate' : 'Activate',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hotel.isActive! ? Colors.orange : Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Add booking/management functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Booking management coming soon!'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: const Text('Manage Bookings'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}