// AddHotelScreen.dart with Cloudinary
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../widgets/form/add-hotel/hotel_type_selector.dart';
import '../widgets/form/add-hotel/facilities_selector.dart';
import '../widgets/form/add-hotel/image_uploader.dart';

class AddHotelScreen extends StatefulWidget {
  @override
  _AddHotelScreenState createState() => _AddHotelScreenState();
}

class _AddHotelScreenState extends State<AddHotelScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _adultCapacityController =
  TextEditingController();
  final TextEditingController _childCapacityController =
  TextEditingController();

  String _selectedType = "Hotel";
  List<String> _selectedFacilities = [];
  List<String> _imagePaths = [];
  bool _isLoading = false;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<List<String>> _uploadImages(List<String> imagePaths) async {
    List<String> downloadUrls = [];

    // Ensure .env is loaded
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      print("Error loading .env file: $e");
    }

    final String? cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final String? uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];

    // Debug: Print configuration
    print('Debug - Cloudinary Config:');
    print('Cloud Name: ${cloudName != null ? "Set" : "Missing"}');
    print('Upload Preset: ${uploadPreset != null ? "Set" : "Missing"}');

    if (cloudName == null || uploadPreset == null) {
      print('Error: Cloudinary configuration is missing from .env file.');
      throw Exception('Cloudinary configuration is missing.');
    }

    try {
      // Initialize Cloudinary
      final cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);

      for (int i = 0; i < imagePaths.length; i++) {
        File imageFile = File(imagePaths[i]);

        // Check if file exists
        if (!await imageFile.exists()) {
          throw Exception('Image file does not exist: ${imagePaths[i]}');
        }

        print('Debug - Uploading file: ${imageFile.path}');
        print('Debug - File size: ${await imageFile.length()} bytes');

        // Upload to Cloudinary
        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            imageFile.path,
            resourceType: CloudinaryResourceType.Image,
            folder: 'hotel_images',
            publicId: 'hotel_${DateTime.now().millisecondsSinceEpoch}_$i',
          ),
        );


        print('Debug - Upload response: ${response.secureUrl}');

        if (response.secureUrl != null) {
          downloadUrls.add(response.secureUrl!);
          print('Debug - Added URL: ${response.secureUrl}');
        } else {
          throw Exception('Failed to upload image, no URL returned.');
        }
      }
    } catch (e) {
      print('Error uploading images to Cloudinary: $e');
      throw Exception('Failed to upload images to Cloudinary: $e');
    }
    return downloadUrls;
  }

  Future<void> _addHotelToFirebase() async {
    try {
      // Get current user
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Upload images and get download URLs
      List<String> imageUrls = [];
      if (_imagePaths.isNotEmpty) {
        imageUrls = await _uploadImages(_imagePaths);
      }

      // Create hotel data
      Map<String, dynamic> hotelData = {
        'name': _nameController.text.trim(),
        'city': _cityController.text.trim(),
        'country': _countryController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _selectedType,
        'pricePerNight': int.tryParse(_priceController.text) ?? 0,
        'adultCapacity': int.tryParse(_adultCapacityController.text) ?? 0,
        'childCapacity': int.tryParse(_childCapacityController.text) ?? 0,
        'facilities': _selectedFacilities,
        'imageUrls': imageUrls,
        'ownerId': currentUser.uid,
        'ownerEmail': currentUser.email,
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
        'isActive': true,
      };

      // Generate a new key for the hotel
      DatabaseReference newHotelRef = _database.child('hotels').push();

      // Add hotel ID to the data
      hotelData['id'] = newHotelRef.key;

      // Save to Firebase Realtime Database
      await newHotelRef.set(hotelData);

      // Also save to user's hotels list for easy retrieval
      await _database
          .child('userHotels')
          .child(currentUser.uid)
          .child(newHotelRef.key!)
          .set(true);

      print('Hotel added successfully with ID: ${newHotelRef.key}');

    } catch (e) {
      print('Error adding hotel to Firebase: $e');
      throw e;
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _addHotelToFirebase();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hotel added successfully',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Clear form after successful submission
        _clearForm();

      } catch (e) {
        print("Error submitting form: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to add hotel. Please try again.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _cityController.clear();
    _countryController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _adultCapacityController.clear();
    _childCapacityController.clear();
    setState(() {
      _selectedType = "Hotel";
      _selectedFacilities = [];
      _imagePaths = [];
    });
  }

  InputDecoration _buildInputDecoration(
      String label,
      IconData icon,
      Color color,
      ) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.blue.shade700,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: color),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue.shade200, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue.shade600, width: 2.0),
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        title: Text(
          "Add Hotel",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: Colors.blue,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Each field on a separate row
                TextFormField(
                  controller: _nameController,
                  decoration: _buildInputDecoration(
                    "Hotel Name",
                    Icons.hotel,
                    Colors.blue,
                  ),
                  validator:
                      (value) => value!.isEmpty ? "Enter hotel name" : null,
                ),
                SizedBox(height: 16),

                TextFormField(
                  controller: _cityController,
                  decoration: _buildInputDecoration(
                    "City",
                    Icons.location_city,
                    Colors.blue,
                  ),
                  validator: (value) => value!.isEmpty ? "Enter city" : null,
                ),
                SizedBox(height: 16),

                TextFormField(
                  controller: _countryController,
                  decoration: _buildInputDecoration(
                    "Country",
                    Icons.flag,
                    Colors.blue,
                  ),
                  validator: (value) => value!.isEmpty ? "Enter country" : null,
                ),
                SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: _buildInputDecoration(
                    "Description",
                    Icons.description,
                    Colors.blue,
                  ),
                  validator:
                      (value) => value!.isEmpty ? "Enter description" : null,
                ),
                SizedBox(height: 16),

                TextFormField(
                  controller: _priceController,
                  decoration: _buildInputDecoration(
                    "Price/Night",
                    Icons.attach_money,
                    Colors.blue,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? "Enter price" : null,
                ),
                SizedBox(height: 16),

                SizedBox(height: 16),

                TextFormField(
                  controller: _adultCapacityController,
                  decoration: _buildInputDecoration(
                    "Adult Capacity",
                    Icons.people,
                    Colors.blue,
                  ),
                  keyboardType: TextInputType.number,
                  validator:
                      (value) => value!.isEmpty ? "Enter adult capacity" : null,
                ),
                SizedBox(height: 16),

                TextFormField(
                  controller: _childCapacityController,
                  decoration: _buildInputDecoration(
                    "Child Capacity",
                    Icons.child_care,
                    Colors.blue,
                  ),
                  keyboardType: TextInputType.number,
                  validator:
                      (value) => value!.isEmpty ? "Enter child capacity" : null,
                ),
                SizedBox(height: 24),

                HotelTypeSelector(
                  selectedType: _selectedType,
                  onTypeChanged:
                      (newType) => setState(() => _selectedType = newType),
                ),
                SizedBox(height: 24),

                FacilitiesSelector(
                  selectedFacilities: _selectedFacilities,
                  onFacilitiesChanged:
                      (newFacilities) =>
                      setState(() => _selectedFacilities = newFacilities),
                ),
                SizedBox(height: 24),

                ImagePickerWidget(
                  onImagesSelected:
                      (imagePaths) => setState(() => _imagePaths = imagePaths),
                ),
                SizedBox(height: 32),

                Container(
                  width: 200,
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submitForm,
                    icon: _isLoading
                        ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Icon(Icons.save),
                    label: Text(_isLoading ? "Adding Hotel..." : "Submit Hotel"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}