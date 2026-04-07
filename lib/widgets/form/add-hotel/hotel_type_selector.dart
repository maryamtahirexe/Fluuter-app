// HotelTypeSelector.dart
import 'package:flutter/material.dart';

class HotelTypeSelector extends StatelessWidget {
  final String selectedType;
  final Function(String) onTypeChanged;

  HotelTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  final List<String> _hotelTypes = ["Hotel", "Resort", "Motel", "Guesthouse"];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hotel Type",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.start,
          spacing: 10,
          children: _hotelTypes.map((type) {
            final isSelected = selectedType == type;
            return ChoiceChip(
              label: Text(type),
              selected: isSelected,
              checkmarkColor: Colors.white,
              selectedColor: Colors.blueAccent,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              onSelected: (_) => onTypeChanged(type),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            );
          }).toList(),
        ),
      ],
    );
  }
}
