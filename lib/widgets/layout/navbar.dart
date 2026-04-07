import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavBar({Key? key, required this.currentIndex, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final bool isLoggedIn = snapshot.hasData && snapshot.data != null;

        final List<BottomNavigationBarItem> items = isLoggedIn
            ? _getLoggedInItems()
            : _getLoggedOutItems();

        return BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) async {
            // If logout item is tapped (last item, index 4)
            if (isLoggedIn && index == 4) {
              await FirebaseAuth.instance.signOut();

              // Define your protected routes
              final protectedRoutes = ['/my-hotels', '/add-hotel', '/bookings'];

              // Check if current route is protected
              final currentRoute = ModalRoute.of(context)?.settings.name;
              if (protectedRoutes.contains(currentRoute)) {
                // Redirect to home
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
              return;
            }

            onTap(index);
          },
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: items,
        );
      },
    );
  }

  List<BottomNavigationBarItem> _getLoggedInItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.search),
        label: 'Search',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.hotel),
        label: 'My Hotels',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.add_business),
        label: 'Add Hotel',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.book_online),
        label: 'Bookings',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.logout),
        label: 'Logout',
      ),
    ];
  }

  List<BottomNavigationBarItem> _getLoggedOutItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.search),
        label: 'Browse',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.login),
        label: 'Sign In',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_add),
        label: 'Sign Up',
      ),
    ];
  }
}
