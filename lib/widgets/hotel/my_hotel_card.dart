import 'package:flutter/material.dart';
import 'info_box.dart';
import '../../models/hotel.dart';

class HotelCard extends StatelessWidget {
  final Hotel hotel;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  HotelCard({
    required this.hotel,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hotel.name!,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(hotel.description!, style: TextStyle(color: Colors.blue)),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InfoBox(
                  icon: Icons.location_on,
                  text: '${hotel.city}, ${hotel.country}',
                ),
                InfoBox(icon: Icons.hotel, text: hotel.type!),
                InfoBox(
                  icon: Icons.attach_money,
                  text: '\$${hotel.pricePerNight} / night',
                ),
                InfoBox(
                  icon: Icons.person,
                  text:
                      '${hotel.adultCapacity} adults, ${hotel.childCapacity} children',
                ),
              ],
            ),
            SizedBox(height: 30),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to the specific hotel details page
                  Navigator.pushNamed(
                    context,
                    '/my-hotels/${hotel.id}', // Replace 'hotel.id' with the actual field name of hotel ID
                  );
                },
                child: Text(
                  'View Details',
                  style: TextStyle(color: Colors.blue), // Text color
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // Background color
                  foregroundColor: Colors.blue, // Ripple color
                  side: BorderSide(
                    color: Colors.blue,
                    width: 1.5,
                  ), // Border color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
