import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'cart_screen.dart';
import 'product_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final PageController _pageController = PageController();

  // Activity 4: Splash already fetched the user (from prefs on
  // cold-start, or from the fresh login response) and passed it
  // here as route arguments — reuse it instead of hitting
  // SharedPreferences again, which was causing a second, redundant
  // loading state on the Profile tab.
  User? _user;
  bool _resolved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_resolved) return;
    _resolved = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      _user = User.fromJson(args);
    } else {
      // Fallback only: Home reached without arguments somehow.
      UserService().getUser().then((u) {
        if (!mounted) return;
        setState(() {
          _user = u;
        });
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isCartScreen = _selectedIndex == 1;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 2,
          backgroundColor: const Color(0xFF3840A2),
          foregroundColor: Colors.white,
          title: CustomText(
            text: _selectedIndex == 0
                ? 'Shop'
                : _selectedIndex == 1
                ? 'Cart'
                : 'Profile',
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings, size: 24.sp, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),

        // Enhancement 2: Chat is a FloatingActionButton instead of
        // a BottomNavigationBar item; hidden on the Cart tab.
        floatingActionButton: isCartScreen
            ? null
            : FloatingActionButton(
                backgroundColor: const Color(0xFFF1C40F),
                foregroundColor: const Color(0xFF1E1E1E),
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Chat opened')));
                },
                child: const Icon(Icons.chat),
              ),

        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: [
            const ProductScreen(),
            const CartScreen(),
            // Enhancement 3: Real ProfileScreen fed by the user data
            // already carried over from splash — no second fetch.
            _user == null
                ? const Center(child: CircularProgressIndicator())
                : ProfileScreen(user: _user!),
          ],
          onPageChanged: (page) {
            setState(() {
              _selectedIndex = page;
            });
          },
        ),

        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          currentIndex: _selectedIndex,
          onTap: _onTappedBar,
          selectedItemColor: const Color(0xFF3840A2),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.shop_2), label: 'Shop'),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
    });

    _pageController.jumpToPage(value);
  }
}
