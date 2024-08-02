import 'package:flutter/material.dart';
import 'package:intellipark/pages/main_pages/landingpage.dart';
import 'package:intellipark/pages/main_pages/loginpage.dart';
import 'package:intellipark/widgets/custom_nav_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IntelliPark',
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash', // Set the initial route to the splash screen
      routes: {
        '/splash': (context) =>
            const MyHomePage(title: 'IntelliPark'), // Splash screen
        '/': (context) => const Landingpage(), // Main landing page
        '/loginpage': (context) => const LoginPage(),
        '/home': (context) => const CustomNavBar(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 6), () {
      Navigator.pushReplacementNamed(context, '/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 255, 255, 255),
        ),
        child: Column(
          children: [
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20), // spacing between text and button
                Image.asset(
                  'assets/images/parkingicon.png',
                  fit: BoxFit.cover,
                  height: 170,
                  width: 170,
                ),
              ],
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  'Campus Parking Simplified',
                  style: TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
