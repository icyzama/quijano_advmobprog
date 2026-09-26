import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants.dart';
import '../widgets/custom_text.dart';
import '../widgets/lab4_components.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'product_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: NuLogo(size: 34),
        ),
        title: const CustomText(
          text: 'NU Commerce',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          // Enhancement 3: Navigate to Settings (theme switch lives on that page).
          IconButton(
            icon: Icon(Icons.settings, size: 24.sp),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          ProductScreen(),
          CartScreen(),
          ProfileScreen(),
        ],
      ),
      // Enhancement 2: Chat is a floating action instead of a bottom-nav item.
      floatingActionButton: _selectedIndex == 1
          ? null
          : FloatingActionButton(
              tooltip: 'Open chat',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat opened')),
              ),
              child: const Icon(Icons.chat),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _pageController.jumpToPage(index);
          });
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag), label: 'Shop'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
