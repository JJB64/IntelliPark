import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const String baseUrl = 'https://intellipark-430801.nw.r.appspot.com';

class SavedLocationsPage extends StatefulWidget {
  const SavedLocationsPage({Key? key}) : super(key: key);

  @override
  _SavedLocationsPageState createState() => _SavedLocationsPageState();
}

class _SavedLocationsPageState extends State<SavedLocationsPage> {
  List<Map<String, dynamic>> locations = [];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<String?> getJwtToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<void> _loadLocations() async {
    final jwtToken = await getJwtToken();
    if (jwtToken == null) {
      print('JWT token not found');
      return;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/get_user_locations'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final locationData = jsonDecode(response.body);
      print('Location data: $locationData'); // Debug print
      setState(() {
        locations = List<Map<String, dynamic>>.from(
          locationData.map<Map<String, dynamic>>(
            (location) => Map<String, dynamic>.from(location),
          ),
        );
      });
    } else {
      print(
          'Failed to load locations: ${response.statusCode} - ${response.reasonPhrase}');
      print('Response body: ${response.body}'); // Debugging
    }
  }

  void _openMap(String coordinates) async {
    String googleUrl =
        'https://www.google.com/maps/search/?api=1&query=$coordinates';
    if (await canLaunch(googleUrl) != null) {
      await launch(googleUrl);
    } else {
      throw 'Could not open the map.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Locations'),
      ),
      body: locations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final location = locations[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text('Location: ${location['locationid']}'),
                    subtitle: Text('Saved at: ${location['createdAt']}'),
                    onTap: () {
                      print(
                          "Coordinates: ${location['locationid']}"); // Debug print to check the data
                      _openMap(location['locationid']);
                    },
                  ),
                );
              },
            ),
    );
  }
}
