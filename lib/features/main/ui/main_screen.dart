import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../../../extensions/build_context_extension.dart';
import '../../../screens/home/postpage.dart';
import '../../../screens/location/locationpage.dart';
import '../../../screens/post/postpage.dart';
import '../../../screens/friends/friendpage.dart';
import '../../../screens/profile/myprofile.dart';
import '../../../theme/app_colors.dart';

const List<Widget> _screens = [
  MyHome(),
  Locationpage(),
  Postpage(),
  Friendpage(),
  MyProfile(),
];

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<PersistentBottomNavBarItem> _navBarsItems(
    BuildContext context,
    Color selectedColor,
    Color unselectedColor,
  ) {
    return [
      PersistentBottomNavBarItem(
        icon: Icon(Icons.home, color: selectedColor),
        inactiveIcon: Icon(Icons.home_outlined, color: unselectedColor),
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.location_on, color: selectedColor),
        inactiveIcon: Icon(Icons.location_on_outlined, color: unselectedColor),
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.add_circle, color: selectedColor),
        inactiveIcon: Icon(Icons.add_circle_outline, color: unselectedColor),
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.people, color: selectedColor),
        inactiveIcon: Icon(Icons.people_outline, color: unselectedColor),
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.person, color: selectedColor),
        inactiveIcon: Icon(Icons.person_outline, color: unselectedColor),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor =
        context.isDarkMode ? AppColors.blueberry100 : AppColors.blueberry100;
    final unselectedColor =
        context.isDarkMode ? AppColors.mono40 : AppColors.mono60;
    return Scaffold(
      body: PersistentTabView(
        context,
        controller: _controller,
        screens: _screens,
        items: _navBarsItems(
          context,
          selectedColor,
          unselectedColor,
        ),
        confineToSafeArea: true,
        backgroundColor: context.secondaryWidgetColor,
        handleAndroidBackButtonPress: true,
        resizeToAvoidBottomInset: true,
        stateManagement: true,
        hideNavigationBarWhenKeyboardAppears: true,
        decoration: NavBarDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
          colorBehindNavBar: context.secondaryBackgroundColor,
        ),
        popBehaviorOnSelectedNavBarItemPress: PopBehavior.all,
        animationSettings: const NavBarAnimationSettings(
          navBarItemAnimation: ItemAnimationSettings(
            // Navigation Bar's items animation properties.
            duration: Duration(milliseconds: 400),
            curve: Curves.ease,
          ),
          screenTransitionAnimation: ScreenTransitionAnimationSettings(
            // Screen transition animation on change of selected tab.
            animateTabTransition: true,
            duration: Duration(milliseconds: 300),
            screenTransitionAnimationType: ScreenTransitionAnimationType.fadeIn,
          ),
          onNavBarHideAnimation: OnHideAnimationSettings(
            duration: Duration(milliseconds: 100),
            curve: Curves.bounceInOut,
          ),
        ),
        navBarStyle: NavBarStyle.style17,
      ),
    );
  }
}
