import 'package:flutter/material.dart';

class FacilitiesGrid extends StatelessWidget {
  final List<String> facilities;

  const FacilitiesGrid({super.key, required this.facilities});

  @override
  // Helper method for facilities grid
  Widget build(BuildContext context) {
    // Map common facilities to appropriate icons
    IconData getIconForFacility(String facility) {
      final String lowercaseFacility = facility.toLowerCase();
      if (lowercaseFacility.contains('wifi')) return Icons.wifi;
      if (lowercaseFacility.contains('pool')) return Icons.pool;
      if (lowercaseFacility.contains('parking')) return Icons.local_parking;
      if (lowercaseFacility.contains('restaurant') || lowercaseFacility.contains('food')) return Icons.restaurant;
      if (lowercaseFacility.contains('gym') || lowercaseFacility.contains('fitness')) return Icons.fitness_center;
      return Icons.check_circle;
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: facilities.map((facility) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(getIconForFacility(facility), size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                facility,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
