import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/hotel.dart';
import '../widgets/hotel_card.dart';
import '../widgets/layout/hero_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  bool _isLoading = true;
  String _errorMessage = '';
  List<Hotel> _hotels = [];
  List<Hotel> _filteredHotels = [];
  String _currentSortOption = 'createdAt';
  bool _isLoadingMore = false;

  // Pagination variables
  int _itemsPerPage = 10;
  int _currentPage = 0;
  List<Hotel> _displayedHotels = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchHotels();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        _loadMoreHotels();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchHotels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Listen to hotels data from Firebase
      final hotelsRef = _database.child('hotels');
      final snapshot = await hotelsRef.get();

      if (snapshot.exists) {
        List<Hotel> fetchedHotels = [];

        Map<dynamic, dynamic> hotelsData = snapshot.value as Map<dynamic, dynamic>;

        hotelsData.forEach((key, value) {
          try {
            // Convert Firebase data to Hotel object
            Map<String, dynamic> hotelMap = Map<String, dynamic>.from(value);
            hotelMap['id'] = key; // Ensure ID is set

            Hotel hotel = Hotel.fromFirebaseJson(hotelMap);

            // Only include active hotels
            if (hotel.isActive ?? true) {
              fetchedHotels.add(hotel);
            }
          } catch (e) {
            print('Error parsing hotel data for key $key: $e');
          }
        });

        setState(() {
          _hotels = fetchedHotels;
          _applySort();
          _isLoading = false;
        });
      } else {
        setState(() {
          _hotels = [];
          _filteredHotels = [];
          _displayedHotels = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load hotels: $e';
        _isLoading = false;
      });
      print('Error fetching hotels: $e');
    }
  }

  void _applySort() {
    List<Hotel> sortedHotels = List.from(_hotels);

    switch (_currentSortOption) {
      case 'pricePerNightAsc':
        sortedHotels.sort((a, b) => (a.pricePerNight ?? 0).compareTo(b.pricePerNight ?? 0));
        break;
      case 'pricePerNightDesc':
        sortedHotels.sort((a, b) => (b.pricePerNight ?? 0).compareTo(a.pricePerNight ?? 0));
        break;
      case 'name':
        sortedHotels.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
        break;
      case 'createdAt':
        sortedHotels.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        break;
    }

    _filteredHotels = sortedHotels;
    _currentPage = 0;
    _loadInitialPage();
  }

  void _loadInitialPage() {
    int endIndex = (_currentPage + 1) * _itemsPerPage;
    if (endIndex > _filteredHotels.length) {
      endIndex = _filteredHotels.length;
    }

    setState(() {
      _displayedHotels = _filteredHotels.sublist(0, endIndex);
    });
  }

  Future<void> _loadMoreHotels() async {
    // Check if there are more items to load
    if ((_currentPage + 1) * _itemsPerPage >= _filteredHotels.length || _isLoadingMore) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate network delay for better UX
    await Future.delayed(Duration(milliseconds: 500));

    int nextPage = _currentPage + 1;
    int startIndex = nextPage * _itemsPerPage;
    int endIndex = (nextPage + 1) * _itemsPerPage;

    if (endIndex > _filteredHotels.length) {
      endIndex = _filteredHotels.length;
    }

    if (startIndex < _filteredHotels.length) {
      List<Hotel> newHotels = _filteredHotels.sublist(startIndex, endIndex);

      setState(() {
        _displayedHotels.addAll(newHotels);
        _currentPage = nextPage;
        _isLoadingMore = false;
      });
    } else {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshHotels() async {
    setState(() {
      _currentPage = 0;
      _displayedHotels = [];
    });
    await _fetchHotels();
  }

  Widget _buildStatsRow() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_filteredHotels.length} hotels found',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            'Showing ${_displayedHotels.length} of ${_filteredHotels.length}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotels',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: Colors.blue,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (String value) {
              setState(() {
                _currentSortOption = value;
              });
              _applySort();
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'pricePerNightAsc',
                child: Text('Price: Low to High'),
              ),
              const PopupMenuItem<String>(
                value: 'pricePerNightDesc',
                child: Text('Price: High to Low'),
              ),
              const PopupMenuItem<String>(
                value: 'name',
                child: Text('Sort by Name'),
              ),
              const PopupMenuItem<String>(
                value: 'createdAt',
                child: Text('Newest First'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshHotels,
          ),
        ],
      ),
      body: _isLoading && _displayedHotels.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty && _displayedHotels.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchHotels,
              icon: Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      )
          : _hotels.isEmpty && !_isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hotel_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No Hotels Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Be the first to add a hotel!',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshHotels,
              icon: Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _refreshHotels,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: 1 + // Hero section
              (_hotels.isNotEmpty ? 1 : 0) + // Stats row (only if hotels exist)
              _displayedHotels.length + // Hotel cards
              (_isLoadingMore ? 1 : 0), // Loading indicator
          itemBuilder: (context, index) {
            // Hero Section (always first)
            if (index == 0) {
              return HeroSection();
            }

            // Stats row (if hotels exist, comes after hero section)
            if (_hotels.isNotEmpty && index == 1) {
              return _buildStatsRow();
            }

            // Calculate hotel card index
            int hotelCardStartIndex = _hotels.isNotEmpty ? 2 : 1;
            int hotelIndex = index - hotelCardStartIndex;

            // Show loading indicator at the bottom
            if (hotelIndex == _displayedHotels.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Hotel cards
            if (hotelIndex >= 0 && hotelIndex < _displayedHotels.length) {
              final hotel = _displayedHotels[hotelIndex];
              return HotelCard(
                hotel: hotel,
                onTap: () {
                  // Navigate to hotel details and refresh on return
                  Navigator.pushNamed(
                    context,
                    '/hotel-details',
                    arguments: hotel.id,
                  ).then((_) => _refreshHotels());
                },
              );
            }

            // Fallback - should not reach here
            return SizedBox.shrink();
          },
        ),
      ),
    );
  }
}