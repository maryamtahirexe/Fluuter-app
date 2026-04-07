import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HotelReviewsWidget extends StatefulWidget {
  final String hotelId;

  const HotelReviewsWidget({
    Key? key,
    required this.hotelId,
  }) : super(key: key);

  @override
  _HotelReviewsWidgetState createState() => _HotelReviewsWidgetState();
}

class _HotelReviewsWidgetState extends State<HotelReviewsWidget> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _reviewController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      _showSnackBar('Please log in to write a review', Colors.red);
      return;
    }

    String reviewText = _reviewController.text.trim();
    if (reviewText.isEmpty) {
      _showSnackBar('Please write a review', Colors.orange);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create review data
      Map<String, dynamic> reviewData = {
        'userId': currentUser.uid,
        'userEmail': currentUser.email,
        'userName': currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'Anonymous',
        'reviewText': reviewText,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Save review to Firebase
      await _database
          .child('reviews')
          .child(widget.hotelId)
          .push()
          .set(reviewData);

      _reviewController.clear();
      _showSnackBar('Review submitted successfully!', Colors.green);

    } catch (e) {
      _showSnackBar('Failed to submit review: $e', Colors.red);
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
  //
  // Future<void> _deleteReview(String reviewId) async {
  //   bool? confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Delete Review'),
  //         content: const Text('Are you sure you want to delete this review?'),
  //         actions: [
  //           TextButton(
  //             child: const Text('Cancel'),
  //             onPressed: () => Navigator.of(context).pop(false),
  //           ),
  //           TextButton(
  //             child: const Text('Delete', style: TextStyle(color: Colors.red)),
  //             onPressed: () => Navigator.of(context).pop(true),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  //
  //   if (confirmed == true) {
  //     try {
  //       await _database
  //           .child('reviews')
  //           .child(widget.hotelId)
  //           .child(reviewId)
  //           .remove();
  //
  //       _showSnackBar('Review deleted successfully', Colors.green);
  //       _loadReviews();
  //     } catch (e) {
  //       _showSnackBar('Failed to delete review: $e', Colors.red);
  //     }
  //   }
  // }

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

  // String _formatDate(int timestamp) {
  //   DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  //   return "${date.day}/${date.month}/${date.year}";
  // }
  //
  // bool _canDeleteReview(Map<String, dynamic> review) {
  //   User? currentUser = _auth.currentUser;
  //   return currentUser != null && currentUser.uid == review['userId'];
  // }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviews Header
          Row(
            children: [
              const Icon(Icons.rate_review, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Reviews',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),

          // Write Review Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Write a Review',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reviewController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Share your experience at this hotel...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text('Submit Review'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16)
        ],
      ),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}