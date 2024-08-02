import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = 'https://intellipark-430801.nw.r.appspot.com';

class PassDetails extends StatefulWidget {
  final Map<String, dynamic> pass;

  const PassDetails({Key? key, required this.pass}) : super(key: key);

  @override
  _PassDetailsState createState() => _PassDetailsState();
}

class _PassDetailsState extends State<PassDetails> {
  void _showAlert(String title, String message, bool success) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the alert dialog
                if (success) {
                  Navigator.of(context).pop(); // Close the modal bottom sheet
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Function to get the JWT token from shared preferences
  Future<String?> getJwtToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // Function to request pass approval using API
  Future<void> _requestPassApproval() async {
    final jwtToken = await getJwtToken();
    if (jwtToken == null) {
      _showAlert('Error', 'JWT token not found', false);
      return;
    }

    // Print the passid for debugging
    print('passid: ${widget.pass['passid']}');

    final response = await http.put(
      Uri.parse('$baseUrl/approve_pass'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
      body: jsonEncode({
        'passid': widget.pass['passid'], // Corrected key to 'passid'
        'status': '1',
      }),
    );

    if (response.statusCode == 200) {
      _showAlert('Success', 'Pass approved successfully', true);
    } else if (response.statusCode == 404) {
      _showAlert('Error', 'Pass does not exist!', false);
    } else if (response.statusCode == 409) {
      _showAlert('Error', 'Pass already approved!', false);
    } else {
      _showAlert('Error', 'Failed to approve pass', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isActive = widget.pass['status'] == '1';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pass Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Owner: ${widget.pass['owner']}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Registration Number: ${widget.pass['regNo']}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Make: ${widget.pass['make']}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Model: ${widget.pass['model']}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Role: ${widget.pass['role']}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Institution: ${widget.pass['institution']}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: isActive ? null : _requestPassApproval,
                child: const Text('Request Pass Approval'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isActive ? Colors.grey : Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
