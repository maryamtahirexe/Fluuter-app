// FacilitiesSelector.dart
import 'package:flutter/material.dart';

class FacilitiesSelector extends StatefulWidget {
  final List<String> selectedFacilities;
  final Function(List<String>) onFacilitiesChanged;

  const FacilitiesSelector({super.key,
    required this.selectedFacilities,
    required this.onFacilitiesChanged,
  });

  @override
  _FacilitiesSelectorState createState() => _FacilitiesSelectorState();
}

class _FacilitiesSelectorState extends State<FacilitiesSelector> {
  final List<String> _facilities = ["WiFi", "Pool", "Gym", "Parking", "Spa", "Restaurant"];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Facilities", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.start,
          spacing: 8,
          runSpacing: 8,
          children: _facilities.map((facility) {
            final isSelected = widget.selectedFacilities.contains(facility);
            return FilterChip(
              label: Text(facility),
              selected: isSelected,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              selectedColor: Colors.blueAccent,
              checkmarkColor: Colors.white,
              backgroundColor: Colors.white,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    widget.selectedFacilities.add(facility);
                  } else {
                    widget.selectedFacilities.remove(facility);
                  }
                  widget.onFacilitiesChanged(widget.selectedFacilities);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
