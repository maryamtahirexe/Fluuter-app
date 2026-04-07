// models/hotel.dart
class Hotel {
  final String? id;
  final String? name;
  final String? city;
  final String? country;
  final String? description;
  final String? type;
  final double? pricePerNight;
  final int? adultCapacity;
  final int? childCapacity;
  final List<String>? facilities;
  final List<String>? imageUrls;
  final String? ownerId;
  final String? ownerEmail;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isActive;

  Hotel({
    this.id,
    this.name,
    this.city,
    this.country,
    this.description,
    this.type,
    this.pricePerNight,
    this.adultCapacity,
    this.childCapacity,
    this.facilities,
    this.imageUrls,
    this.ownerId,
    this.ownerEmail,
    this.createdAt,
    this.updatedAt,
    this.isActive,
  });

  // Factory constructor for creating Hotel from Firebase JSON
  factory Hotel.fromFirebaseJson(Map<String, dynamic> json) {
    return Hotel(
      id: json['id'] as String?,
      name: json['name'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      description: json['description'] as String?,
      type: json['type'] as String?,
      pricePerNight: _parseDoubleValue(json['pricePerNight']),
      adultCapacity: _parseIntValue(json['adultCapacity']),
      childCapacity: _parseIntValue(json['childCapacity']),
      facilities: _parseStringList(json['facilities']),
      imageUrls: _parseStringList(json['imageUrls']),
      ownerId: json['ownerId'] as String?,
      ownerEmail: json['ownerEmail'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  // Convert Hotel to JSON for Firebase
  Map<String, dynamic> toFirebaseJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'country': country,
      'description': description,
      'type': type,
      'pricePerNight': pricePerNight,
      'adultCapacity': adultCapacity,
      'childCapacity': childCapacity,
      'facilities': facilities,
      'imageUrls': imageUrls,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }

  // Helper method to safely parse integer values
  static int? _parseIntValue(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  // Helper method to safely parse double values
  static double? _parseDoubleValue(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }


  // Helper method to safely parse string lists
  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return null;
  }

  // Helper method to safely parse DateTime
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  // Create a copy of the hotel with updated fields
  Hotel copyWith({
    String? id,
    String? name,
    String? city,
    String? country,
    String? description,
    String? type,
    double? pricePerNight,
    int? adultCapacity,
    int? childCapacity,
    List<String>? facilities,
    List<String>? imageUrls,
    String? ownerId,
    String? ownerEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Hotel(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      country: country ?? this.country,
      description: description ?? this.description,
      type: type ?? this.type,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      adultCapacity: adultCapacity ?? this.adultCapacity,
      childCapacity: childCapacity ?? this.childCapacity,
      facilities: facilities ?? this.facilities,
      imageUrls: imageUrls ?? this.imageUrls,
      ownerId: ownerId ?? this.ownerId,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Get the first image URL or return a placeholder
  String get primaryImageUrl {
    if (imageUrls != null && imageUrls!.isNotEmpty) {
      return imageUrls!.first;
    }
    return 'https://via.placeholder.com/300x200?text=No+Image';
  }

  // Get location string
  String get location {
    if (city != null && country != null) {
      return '$city, $country';
    } else if (city != null) {
      return city!;
    } else if (country != null) {
      return country!;
    }
    return 'Location not specified';
  }

  // Get facilities as a formatted string
  String get facilitiesString {
    if (facilities == null || facilities!.isEmpty) {
      return 'No facilities listed';
    }
    return facilities!.join(', ');
  }

  // Check if hotel has specific facility
  bool hasFacility(String facility) {
    return facilities?.contains(facility) ?? false;
  }

  @override
  String toString() {
    return 'Hotel{id: $id, name: $name, city: $city, country: $country, type: $type, pricePerNight: $pricePerNight}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Hotel &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Since you might still have references to HotelSearchResponse,
// here's a simple replacement that works with the new structure
class HotelSearchResponse {
  final List<Hotel> data;
  final HotelPagination pagination;

  HotelSearchResponse({
    required this.data,
    required this.pagination,
  });
}

class HotelPagination {
  final int page;
  final int pages;
  final int total;
  final int limit;

  HotelPagination({
    required this.page,
    required this.pages,
    required this.total,
    required this.limit,
  });

  factory HotelPagination.fromTotalCount(int total, int itemsPerPage, int currentPage) {
    final totalPages = (total / itemsPerPage).ceil();
    return HotelPagination(
      page: currentPage,
      pages: totalPages,
      total: total,
      limit: itemsPerPage,
    );
  }
}