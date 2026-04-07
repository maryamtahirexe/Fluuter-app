// https://medium.com/icnh/a-star-rating-widget-for-flutter-41560f82c8cb
import 'package:flutter/material.dart';

class StarRatingSelector extends StatefulWidget {
  final int initialRating;
  final Function(int) onRatingChanged;

  const StarRatingSelector({super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
  });

  @override
  _StarRatingSelectorState createState() => _StarRatingSelectorState();
}

class _StarRatingSelectorState extends State<StarRatingSelector> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Star Rating",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentRating = index + 1;
                });
                widget.onRatingChanged(_currentRating);
              },
              child: Icon(
                index < _currentRating ? Icons.star : Icons.star_border,
                color: Colors.blue,
                size: 32,
              ),
            );
          }),
        ),
        SizedBox(height: 4),
        Text(
          _currentRating > 0 ? "$_currentRating-star rating selected" : "No rating selected",
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        SizedBox(height: 30),
      ],
    );
  }
}