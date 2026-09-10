import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'cart_screen.dart';
import 'product_screen.dart';
import 'profile_screen.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialIndex = 0});

  // Enhancement 2: Lets other screens open HomeScreen directly on Cart.
  final int initialIndex;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  late final PageController _pageController;
  String _profileTitle = 'Profile';

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadProfileTitle();
  }

  Future<void> _loadProfileTitle() async {
    final userData = await UserService().getUserData();
    if (!mounted) return;

    final firstName = (userData['firstName'] ?? '').toString().trim();
    final lastName = (userData['lastName'] ?? '').toString().trim();
    final username = (userData['username'] ?? '').toString().trim();

    final resolvedName = [firstName, lastName].join(' ').trim().isNotEmpty
        ? [firstName, lastName].join(' ').trim()
        : username.isNotEmpty
        ? username
        : 'Profile';

    setState(() {
      _profileTitle = resolvedName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 2,
          title: CustomText(
            text: _selectedIndex == 1
                ? 'Cart'
                : _selectedIndex == 2
                ? _profileTitle
                : 'Home',
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings, size: 24.sp),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        // PageView content is swiped only via the bottom nav taps below.
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: const <Widget>[
            ProductScreen(),
            CartScreen(),
            // Enhancement 3: Profile tab renders the saved User model and
            // that user's cart, replacing the old placeholder page.
            ProfileScreen(),
          ],
          onPageChanged: (page) {
            setState(() {
              _selectedIndex = page;
            });
          },
        ),
        // Enhancement 2: Cart navigation is shown as a right-side
        // FloatingActionButton and hidden while the Cart screen is active.
        floatingActionButton: _selectedIndex == 1
            ? null
            : FloatingActionButton(
                onPressed: () => _onTappedBar(1),
                child: const Icon(Icons.shopping_cart),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: BottomAppBar(
          child: SizedBox(
            height: 64.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  tooltip: 'Shop',
                  onPressed: () => _onTappedBar(0),
                  icon: Icon(
                    Icons.shop_2,
                    color: _selectedIndex == 0
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
                IconButton(
                  tooltip: 'Profile',
                  onPressed: () => _onTappedBar(2),
                  icon: Icon(
                    Icons.person,
                    color: _selectedIndex == 2
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Keeps the bottom nav selection and PageView page in sync.
  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
    });
    _pageController.jumpToPage(value);
  }
}
