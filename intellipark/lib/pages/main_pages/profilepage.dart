import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:http/http.dart' as http;
import 'package:intellipark/pages/main_pages/landingpage.dart';
import 'package:intellipark/pages/main_pages/savedlocationpage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const String baseUrl = 'https://intellipark-430801.nw.r.appspot.com';

enum Menu { ChangePassword, logout }

List<PopupMenuEntry<Menu>> getPopupMenuItems() {
  return <PopupMenuEntry<Menu>>[
    const PopupMenuItem<Menu>(
      value: Menu.ChangePassword,
      child: ListTile(
        leading: Icon(Icons.lock),
        title: Text('Change Password'),
      ),
    ),
    const PopupMenuItem<Menu>(
      value: Menu.logout,
      child: ListTile(
        leading: Icon(Icons.logout),
        title: Text('Logout'),
      ),
    ),
  ];
}

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? userName;
  String? userGender;
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  static Future<String?> getJwtToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  List<Map<String, dynamic>> vehicles = [];
  List<Map<String, dynamic>> passes = [];

  void sendEmailRequest() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'admin@intelliparkAshesi.com',
      query: encodeQueryParameters(<String, String>{
        'subject': 'Request to Change Vehicle Details',
        'body':
            'I am writing this mail to request some changes be made to the details of my vehicle. '
                'Here are the details:\n\n'
                'Thank you.\n\nBest Regards, $userName\n'
      }),
    );

    if (await canLaunch(emailUri.toString())) {
      await launch(emailUri.toString());
    } else {
      print('Could not launch email app');
    }
  }

  String encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final jwtToken = await getJwtToken();
    if (jwtToken == null) {
      print('JWT token not found');
      return;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/get_user'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      setState(() {
        userName = userData['name'];
        userGender = userData['gender'];
      });
    } else {
      print(
          'Failed to load user data: ${response.statusCode} - ${response.reasonPhrase}');
      print('Response body: ${response.body}'); // Debugging
    }
  }

  Future<void> _changePassword(String oldPassword, String newPassword) async {
    final jwtToken = await getJwtToken();
    if (jwtToken == null) {
      print('JWT token not found');
      return;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/change_password'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      print('Password changed successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
    } else if (response.statusCode == 401) {
      print('Invalid old password');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid old password')),
      );
    } else {
      print('Failed to change password');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to change password')),
      );
    }
  }

  void _changePasswordForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _oldPasswordController,
                decoration: const InputDecoration(labelText: 'Old Password'),
                obscureText: true,
              ),
              TextField(
                controller: _newPasswordController,
                decoration: const InputDecoration(labelText: 'New Password'),
                obscureText: true,
              ),
              TextField(
                controller: _confirmPasswordController,
                decoration:
                    const InputDecoration(labelText: 'Confirm New Password'),
                obscureText: true,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_newPasswordController.text ==
                    _confirmPasswordController.text) {
                  _changePassword(
                    _oldPasswordController.text,
                    _newPasswordController.text,
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New passwords do not match')),
                  );
                }
              },
              child: const Text('Change Password'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Settings button with PopupMenuButton
          Positioned(
            top: 40,
            right: 20,
            child: PopupMenuButton<Menu>(
              icon: const Icon(Icons.settings,
                  color: Color.fromARGB(255, 20, 42, 203)),
              onSelected: (Menu item) {
                // Handle the selected menu item
                switch (item) {
                  case Menu.ChangePassword:
                    _changePasswordForm();
                    break;
                  case Menu.logout:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const Landingpage()),
                    );
                    break;
                }
              },
              itemBuilder: (BuildContext context) => getPopupMenuItems(),
            ),
          ),

          // Profile picture
          Positioned(
            top: 90,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 158,
                height: 158,
                decoration: BoxDecoration(
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(100, 100, 100, 0.15),
                      offset: Offset(0, 4),
                      blurRadius: 20,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                  shape: BoxShape.circle,
                  image: const DecorationImage(
                    image: AssetImage('assets/images/profile.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),

          // Name and Gender
          Positioned(
            top: 270,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  userName ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  userGender ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          // View marked parking spots button
          Positioned(
            top: 350,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SavedLocationsPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor:
                      const Color.fromARGB(255, 20, 42, 203), // Text color
                ),
                child: const Text('View marked parking spots'),
              ),
            ),
          ),

          Positioned(
            top: 420,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  sendEmailRequest();
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor:
                      const Color.fromARGB(255, 20, 42, 203), // Text color
                ),
                child: const Text('Request Vehicle details Change'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
