import 'package:firebase/screens/add_hotel_screen.dart';
import 'package:firebase/screens/bookings_screen.dart';
import 'package:firebase/screens/home_screen.dart';
import 'package:firebase/screens/hotel_details_screen.dart';
import 'package:firebase/screens/my_hotel_screen.dart';
import 'package:firebase/screens/my_hotels_screen.dart';
import 'package:firebase/screens/sign_in_screen.dart';
import 'package:firebase/screens/sign_up_screen.dart';
import 'package:firebase/widgets/layout/navbar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyCNTlg70jpSG9YTsgtGLLV6uIMXceddHbU",
        authDomain: "lab-10-90554.firebaseapp.com",
        projectId: "lab-10-90554",
        storageBucket: "lab-10-90554.firebasestorage.app",
        messagingSenderId: "901530321729",
        appId: "1:901530321729:web:fc76ea7f0adbb07dc617c0",
        measurementId: "G-8NPD9JVXV3",
        databaseURL: "https://lab-10-90554-default-rtdb.firebaseio.com",
      ),
    );
  } else {
    await Firebase.initializeApp(); // Android/iOS uses google-services.json
  }

  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null && message.contains('[MY_TAG]')) {
      debugPrintSynchronously(message);
    }
  };

  runApp(HotelBookingApp());
}

class HotelBookingApp extends StatelessWidget {
  const HotelBookingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hotel Booking App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainScreen(),
      routes: {
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/add-hotel': (context) => AddHotelScreen(),
        '/my-hotels': (context) => MyHotelsScreen(),
        '/hotel-details': (context) {
          final hotelId = ModalRoute.of(context)!.settings.arguments as String;
          return HotelDetailScreen(hotelId: hotelId);
        },
      },
      onGenerateRoute: (settings) {
        if (settings.name!.startsWith('/my-hotels/')) {
          final hotelId = settings.name!.split('/').last; // Extract hotelId from URL
          // return MaterialPageRoute(
          //   builder: (context) => MyHotelScreen(hotelId: hotelId),
          // );
        }
        return null; // Return null for other routes to fall back to default behavior
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Screens for logged out users
  final List<Widget> _loggedOutScreens = [
    const HomeScreen(),
    const HomeScreen(), // Browse - you might want a separate browse screen
    const SignInScreen(),
    const SignUpScreen(),
  ];

  // Screens for logged in users
  final List<Widget> _loggedInScreens = [
    const HomeScreen(), // Search
    MyHotelsScreen(), // My Hotels
    AddHotelScreen(), // Add Hotel
    const BookingScreen(), // Bookings - replace with actual screen
    // Note: Logout is handled in navbar, no screen needed
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final bool isLoggedIn = snapshot.hasData && snapshot.data != null;

        // Get the appropriate screens based on auth status
        final screens = isLoggedIn ? _loggedInScreens : _loggedOutScreens;

        // Reset index if it's out of bounds for the current screen set
        if (_currentIndex >= screens.length) {
          _currentIndex = 0;
        }

        return Scaffold(
          body: screens[_currentIndex],
          bottomNavigationBar: NavBar(
            currentIndex: _currentIndex,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }
}