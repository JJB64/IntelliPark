import 'package:flutter/material.dart';
import 'package:intellipark/pages/main_pages/Passes.dart';
import 'package:intellipark/pages/main_pages/homepage.dart';
import 'package:intellipark/pages/main_pages/profilepage.dart';

class CustomNavBar extends StatefulWidget {
  const CustomNavBar({super.key});

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // final user = Provider.of<UserProvider>(context).user;
    final List<Widget> _widgetOptions = [
      const HomePage(),
      const Passes(),
      const Profile(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_filled_outlined),
              label: 'Passes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color.fromARGB(255, 20, 42, 203),
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
