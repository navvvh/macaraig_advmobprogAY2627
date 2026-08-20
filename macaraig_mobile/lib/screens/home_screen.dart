import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/custom_text.dart';
import 'cart_screen.dart';
import 'product_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({
    super.key,
    this.username = '',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final PageController _pageController =
      PageController();

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
              icon: Icon(
                Icons.settings,
                size: 24.sp,
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/settings',
                );
              },
            ),
          ],
        ),

        // Enhancement 2:
        // Chat is now a FloatingActionButton instead of
        // a BottomNavigationBar item.
        floatingActionButton: isCartScreen
            ? null
            : FloatingActionButton(
                onPressed: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Chat opened',
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.chat),
              ),

        floatingActionButtonLocation:
            FloatingActionButtonLocation.endFloat,

        body: PageView(
          physics:
              const NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: const [
            ProductScreen(),
            CartScreen(),
            _ProfilePlaceholder(),
          ],
          onPageChanged: (page) {
            setState(() {
              _selectedIndex = page;
            });
          },
        ),

        bottomNavigationBar:
            BottomNavigationBar(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          currentIndex: _selectedIndex,
          onTap: _onTappedBar,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.shop_2),
              label: 'Shop',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
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

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomText(
        text: 'Profile',
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}