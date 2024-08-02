import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intellipark/pages/main_pages/passdetailspage.dart';

const String baseUrl = 'https://intellipark-430801.nw.r.appspot.com';

class Passes extends StatefulWidget {
  const Passes({super.key});

  @override
  _PassesState createState() => _PassesState();
}

class _PassesState extends State<Passes> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController ownerController = TextEditingController();
  final TextEditingController regNoController = TextEditingController();
  final TextEditingController makeController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController institutionController = TextEditingController();
  String? userEmail;
  String? userInstitution;
  String? userRole;

  static Future<String?> getJwtToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  List<Map<String, dynamic>> vehicles = [];
  List<Map<String, dynamic>> passes = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPasses();
    _loadVehicles();
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
        userEmail = userData['email'];
        userInstitution = userData['institution'];
        userRole = userData['role'];
        ownerController.text = userEmail ?? '';
        institutionController.text = userInstitution ?? '';
        roleController.text = userRole ?? '';
      });
    } else {
      print(
          'Failed to load user data: ${response.statusCode} - ${response.reasonPhrase}');
      print('Response body: ${response.body}'); // Debugging
    }
  }

  Future<void> _loadVehicles() async {
    final jwtToken = await getJwtToken();
    if (jwtToken == null) {
      print('JWT token not found');
      return;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/get_user_vehicles'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final vehicleData = jsonDecode(response.body);
      print('Vehicle data: $vehicleData'); // Debug print
      setState(() {
        vehicles = List<Map<String, dynamic>>.from(
          vehicleData.map<Map<String, dynamic>>(
            (vehicle) => Map<String, dynamic>.from(vehicle),
          ),
        );
      });
    } else {
      print(
          'Failed to load vehicles: ${response.statusCode} - ${response.reasonPhrase}');
      print('Response body: ${response.body}'); // Debugging
    }
  }

  Future<void> _loadPasses() async {
    final jwtToken = await getJwtToken();
    if (jwtToken == null) {
      print('JWT token not found');
      return;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/get_user_passes'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final passData = jsonDecode(response.body);
      print('Pass data: $passData'); // Debug print
      setState(() {
        passes = List<Map<String, dynamic>>.from(
          passData.map<Map<String, dynamic>>(
            (pass) => Map<String, dynamic>.from(pass),
          ),
        );
      });
    } else {
      print(
          'Failed to load passes: ${response.statusCode} - ${response.reasonPhrase}');
      print('Response body: ${response.body}'); // Debugging
    }
  }

  Future<void> _refreshPasses() async {
    await _loadPasses();
  }

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
                  _loadPasses(); // Reload passes
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showVehicleSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SingleChildScrollView(
              child: Padding(
                padding: MediaQuery.of(context).viewInsets,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        'Select a Vehicle',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: vehicles.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                                '${vehicles[index]['make']} ${vehicles[index]['model']}'),
                            subtitle:
                                Text('Reg No: ${vehicles[index]['regNo']}'),
                            onTap: () {
                              Navigator.pop(context);
                              _showForm(vehicles[index]);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showForm(Map<String, dynamic> selectedVehicle) {
    ownerController.text = selectedVehicle['owner'] ?? '';
    regNoController.text = selectedVehicle['regNo'] ?? '';
    makeController.text = selectedVehicle['make'] ?? '';
    modelController.text = selectedVehicle['model'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SingleChildScrollView(
              child: Padding(
                padding: MediaQuery.of(context).viewInsets,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextFormField(
                          controller: regNoController,
                          decoration: const InputDecoration(
                              labelText: 'Registration Number'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the registration number';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: makeController,
                          decoration: const InputDecoration(labelText: 'Make'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the make';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: modelController,
                          decoration: const InputDecoration(labelText: 'Model'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the model';
                            }
                            return null;
                          },
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              // Generate QR code data
                              final qrData = jsonEncode({
                                'owner': userEmail,
                                'regNo': regNoController.text,
                                'make': makeController.text,
                                'model': modelController.text,
                                'role': roleController.text,
                                'institution': userInstitution,
                              });

                              // Save pass data with QR code to database
                              final response = await _savePassToDatabase(
                                qrData,
                                ownerController.text,
                                regNoController.text,
                                makeController.text,
                                modelController.text,
                                roleController.text,
                                institutionController.text,
                              );

                              if (response) {
                                Navigator.pop(context);
                                _showAlert('Success', 'Pass Created', true);
                              }
                            }
                          },
                          child: const Text('Create Pass'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      // Reset the form fields when the bottom sheet is dismissed
      ownerController.clear();
      regNoController.clear();
      makeController.clear();
      modelController.clear();
      roleController.clear();
      institutionController.clear();
    });
  }

  Future<bool> _savePassToDatabase(
    String qrData,
    String owner,
    String regNo,
    String make,
    String model,
    String role,
    String institution,
  ) async {
    final jwtToken = await getJwtToken();
    if (jwtToken == null) {
      print('JWT token not found');
      return false;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/create_pass'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'qrCode': qrData,
        'owner': owner,
        'regNo': regNo,
        'make': make,
        'model': model,
        'role': role,
        'institution': institution,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print(
          'Failed to save pass: ${response.statusCode} - ${response.reasonPhrase}');
      print('Response body: ${response.body}'); // Additional debugging info
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'assets/images/parkingicon.png',
              height: 40,
            ),
            const Spacer(),
            const Spacer(),
            const Spacer(),
            const Text(
              'Passes',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 25.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                _showVehicleSelection();
              },
              child: const Text(
                'Create Pass',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPasses,
        child: Center(
          child: passes.isEmpty
              ? const Text('No Passes Found')
              : ListView.builder(
                  itemCount: passes.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                        title: Text(
                            '${passes[index]['make']} ${passes[index]['model']}'),
                        subtitle: Text('Reg No: ${passes[index]['regNo']}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PassDetails(pass: passes[index]),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
