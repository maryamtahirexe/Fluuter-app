import 'dart:convert';
import 'dart:developer' as developer;
import 'package:firebase/models/review_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HotelReviewsListWidget extends StatefulWidget {
  final String hotelId;

  const HotelReviewsListWidget({
    Key? key,
    required this.hotelId,
  }) : super(key: key);

  @override
  _HotelReviewsListWidgetState createState() => _HotelReviewsListWidgetState();
}

class _HotelReviewsListWidgetState extends State<HotelReviewsListWidget> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  List<Map<String, dynamic>> _allReviews = [];
  List<Map<String, dynamic>> _filteredReviews = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  void _showRawReviewsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Raw Reviews Data'),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: SelectableText(
                _allReviews.toString(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadReviews() async {
    try {
      DatabaseEvent event = await _database
          .child('reviews')
          .child(widget.hotelId)
          .orderByChild('createdAt')
          .once();

      if (event.snapshot.exists && event.snapshot.value != null) {
        Map<String, dynamic> reviewsData =
        Map<String, dynamic>.from(event.snapshot.value as Map);

        List<Map<String, dynamic>> reviewsList = [];
        reviewsData.forEach((key, value) {
          Map<String, dynamic> review = Map<String, dynamic>.from(value);
          review['id'] = key;
          reviewsList.add(review);
        });

        // Sort by creation date (newest first)
        reviewsList.sort((a, b) {
          int aTime = a['createdAt'] ?? 0;
          int bTime = b['createdAt'] ?? 0;
          return bTime.compareTo(aTime);
        });

        _showRawReviewsDialog();

        setState(() {
          _allReviews = reviewsList;
          print(_allReviews);
          _filteredReviews = reviewsList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _allReviews = [];
          _filteredReviews = [];
          _isLoading = false;
        });
      }
      print('=== ALL REVIEWS ===');
      print(JsonEncoder.withIndent('  ').convert(_allReviews));
      developer.log('All Reviews Data:', name: 'ReviewsDebug');
      developer.log(_allReviews.toString(), name: 'ReviewsDebug');
    } catch (e) {
      print('Error loading reviews: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterReviews(String filter) async {
    if (filter == 'all') {
      setState(() {
        _selectedFilter = filter;
        _filteredReviews = _allReviews;
      });
      return;
    }

    setState(() {
      _selectedFilter = filter;
      _isLoading = true;
    });

    try {
      // Get predictions from API (now maintains all original fields)
      final predictedReviews = await ReviewService.analyzeReviews(_allReviews);

      setState(() {
        _filteredReviews = predictedReviews.where((review) {
          if (filter == 'good') return review['prediction'] == 'good';
          if (filter == 'bad') return review['prediction'] == 'bad';
          return true;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Filtering error: $e');
      setState(() {
        _filteredReviews = _allReviews;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Filter error: ${e.toString()}'),
            duration: Duration(seconds: 3),
          ));
      }
      }
  String _formatDate(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    bool isSelected = _selectedFilter == value;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) => _filterReviews(value),
      selectedColor: Colors.blue,
      backgroundColor: Colors.grey.shade100,
      checkmarkColor: Colors.white,
      elevation: isSelected ? 2 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

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
          // Header
          Row(
            children: [
              const Icon(Icons.reviews, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Hotel Reviews',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_allReviews.isNotEmpty)
                Text(
                  '${_filteredReviews.length} of ${_allReviews.length}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Filter Chips
          if (_allReviews.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all', Icons.list),
                  const SizedBox(width: 8),
                  _buildFilterChip('Good', 'good', Icons.thumb_up),
                  const SizedBox(width: 8),
                  _buildFilterChip('Bad', 'bad', Icons.thumb_down),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Reviews List
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_allReviews.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No reviews available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This hotel doesn\'t have any reviews yet.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          else if (_filteredReviews.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      _selectedFilter == 'good' ? Icons.thumb_up_outlined : Icons.thumb_down_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No ${_selectedFilter} reviews found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try selecting a different filter.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredReviews.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final review = _filteredReviews[index];

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade100,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                (review['userName'] as String).isNotEmpty
                                    ? (review['userName'] as String)[0].toUpperCase()
                                    : 'A',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review['userName'] ?? 'Anonymous',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDate(review['createdAt']),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          review['reviewText'] ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }
}