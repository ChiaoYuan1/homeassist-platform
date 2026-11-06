import 'package:flutter/material.dart';

import '../../widgets/booking_alert_listener.dart';
import 'bookings_page.dart';
import 'customer_home_page.dart';
import 'profile_page.dart';


class CustomerNavigation
    extends StatefulWidget {
  final int initialIndex;


  const CustomerNavigation({
    super.key,
    this.initialIndex = 0,
  });


  @override
  State<CustomerNavigation>
  createState() =>
      _CustomerNavigationState();
}


class _CustomerNavigationState
    extends State<CustomerNavigation> {
  late int _index;


  final _pages = const [
    CustomerHomePage(),
    BookingsPage(),
    ProfilePage(),
  ];


  @override
  void initState() {
    super.initState();

    _index =
        widget.initialIndex;
  }


  @override
  Widget build(
      BuildContext context,
      ) {
    return BookingAlertListener(
        child: Scaffold(
        body: _pages[_index],

        bottomNavigationBar:
        NavigationBar(
          selectedIndex:
          _index,

          onDestinationSelected:
              (i) {
            setState(() {
              _index = i;
            });
          },

          destinations:
          const [
            NavigationDestination(
              icon:
              Icon(
                Icons.home_outlined,
              ),

              selectedIcon:
              Icon(
                Icons.home,
              ),

              label:
              'Home',
            ),

            NavigationDestination(
              icon:
              Icon(
                Icons
                    .receipt_long_outlined,
              ),

              selectedIcon:
              Icon(
                Icons.receipt_long,
              ),

              label:
              'Bookings',
            ),

            NavigationDestination(
              icon:
              Icon(
                Icons.person_outline,
              ),

              selectedIcon:
              Icon(
                Icons.person,
              ),

              label:
              'Profile',
            ),
          ],
        ),
      ),
    );
  }
}