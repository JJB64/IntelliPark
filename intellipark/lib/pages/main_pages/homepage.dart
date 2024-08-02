import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intellipark/pages/main_pages/Passes.dart';
import 'package:intellipark/widgets/QRCodePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

const String baseUrl = 'https://intellipark-430801.nw.r.appspot.com';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userName;
  String? userRole;
  String? userEmail;
  final TextEditingController VehicleModelController = TextEditingController();
  final TextEditingController VehicleMakeController = TextEditingController();
  final TextEditingController VehicleVinController = TextEditingController();
  final TextEditingController VehicleColorController = TextEditingController();
  final TextEditingController VehicleRegNoController = TextEditingController();
  final TextEditingController VehicleOwnerController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> passes = [];
  List<Map<String, dynamic>> vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPasses();
    _loadVehicles(); // Ensure vehicles are loaded
  }

  static Future<String?> getJwtToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
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
        userRole = userData['role'];
        userEmail = userData['email'];
      });
    } else {
      print(
          'Failed to load user data: ${response.statusCode} - ${response.reasonPhrase}');
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

  void _showVehicleSelection(BuildContext context) async {
    final selectedVehicle = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a Vehicle'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                      '${vehicles[index]['make']} ${vehicles[index]['model']}'),
                  subtitle: Text('Reg No: ${vehicles[index]['regNo']}'),
                  onTap: () {
                    Navigator.pop(context, vehicles[index]);
                  },
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedVehicle != null) {
      // Find the corresponding pass data
      final correspondingPass = passes.firstWhere(
          (pass) => pass['regNo'] == selectedVehicle['regNo'],
          orElse: () => Map<String, dynamic>.from({}));

      if (correspondingPass != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                QRCodePage(qrData: correspondingPass['qrCode']),
          ),
        );
      } else {
        _showAlert('Error', 'No pass data found for selected vehicle.', false);
      }
    }
  }

  void _showAlert2(String title, String message, bool success) {
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
                Navigator.of(context)
                    .pop(); // Ensures only the dialog is closed
              },
            ),
          ],
        );
      },
    );
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
                  Navigator.of(context).pop(); // Close the modal bottom sheet
                }
              },
            ),
          ],
        );
      },
    );
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

  void _resetFormFields() {
    VehicleModelController.clear();
    VehicleMakeController.clear();
    VehicleVinController.clear();
    VehicleColorController.clear();
    VehicleRegNoController.clear();
    VehicleOwnerController.clear();
  }

  Future<void> _AddVehicle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final jwtToken = await getJwtToken();
    if (jwtToken == null) {
      print('JWT token not found');
      return;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/add_vehicle'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'make': VehicleMakeController.text,
        'model': VehicleModelController.text,
        'vin': VehicleVinController.text,
        'color': VehicleColorController.text,
        'regNo': VehicleRegNoController.text,
        'owner': userEmail,
      }),
    );

    if (response.statusCode == 200) {
      print('Vehicle added successfully');
      _showAlert('Success', 'Vehicle added successfully', true);
    } else {
      print(
          'Failed to add vehicle: ${response.statusCode} - ${response.reasonPhrase}');
      _showAlert('Error', 'Failed to add vehicle', false);
    }
  }

  void _showForm() {
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
                          controller: VehicleMakeController,
                          decoration:
                              const InputDecoration(labelText: 'Vehicle Make'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the Vehicle Make';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: VehicleModelController,
                          decoration:
                              const InputDecoration(labelText: 'Vehicle Model'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the Vehicle Model';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: VehicleVinController,
                          decoration:
                              const InputDecoration(labelText: 'Vehicle Vin'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the Vehicle Vin';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: VehicleColorController,
                          decoration:
                              const InputDecoration(labelText: 'Vehicle Color'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the Vehicle Color';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: VehicleRegNoController,
                          decoration: const InputDecoration(
                              labelText: 'Vehicle Registration Number'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the Vehicle Registration Number';
                            }
                            return null;
                          },
                        ),
                        ElevatedButton(
                          onPressed: _AddVehicle,
                          child: const Text('Add Vehicle'),
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
      _resetFormFields();
    });
  }

  Future<void> _saveLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final coordinates = '${position.latitude},${position.longitude}';

    final jwtToken = await getJwtToken();
    if (jwtToken == null) {
      _showAlert2('Error', 'JWT token not found', false);
      return;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/add_location'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'locationid': coordinates,
        'owner': userEmail,
      }),
    );

    if (response.statusCode == 200) {
      _showAlert2('Success', 'Location saved successfully!', true);
    } else {
      _showAlert2('Error', 'Failed to save location', false);
    }
  }

  Future<void> _refreshData() async {
    await _loadPasses();
    await _loadVehicles();
  }

  void _showVehicleList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: vehicles.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(
                '${vehicles[index]['make']} ${vehicles[index]['model']}',
              ),
              subtitle: Text('Reg No: ${vehicles[index]['regNo']}'),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Welcome, ${userName ?? ''}'),
            Image.asset(
              'assets/images/parkingicon.png',
              height: 40,
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Passes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.black),
                    onPressed:
                        _refreshData, // Refresh both passes and vehicles when pressed
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Passes(),
                        ),
                      );
                    },
                    child: const Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 320, // Set a fixed height for the horizontal ListView
                child: passes.isEmpty
                    ? Center(
                        child: SizedBox(
                          width: 330, // Set a fixed width for the default card
                          child: Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(
                                color: Color.fromARGB(255, 237, 237, 237),
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'No Passes Found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: passes.length,
                        itemBuilder: (context, index) {
                          final pass = passes[index];
                          final isActive = pass['status'] == '1';
                          return SizedBox(
                            width: 330, // Set a fixed width for each card
                            child: Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(
                                  color: Color.fromARGB(255, 237, 237, 237),
                                  width: 2,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      constraints: const BoxConstraints(
                                        maxHeight:
                                            200, // Set the max height of the image
                                        maxWidth:
                                            290, // Set the max width of the image
                                      ),
                                      child: Image.asset(
                                        'assets/images/CarIcon.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Reg No: ${pass['regNo']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        Text(
                                          isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            color: isActive
                                                ? Colors.green
                                                : Colors.red,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const Spacer(),
                                        Switch(
                                          value: isActive,
                                          onChanged: (bool value) {
                                            // Handle toggle change
                                          },
                                          activeColor: Colors.green,
                                          inactiveThumbColor: Colors.red,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    _showVehicleSelection(context);
                  },
                  child: const Text('Generate QR Code'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16), // Space between the buttons
              Center(
                child: TextButton(
                  onPressed: () {
                    _showVehicleList(context);
                  },
                  child: Text(
                    'Vehicles: ${vehicles.length}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 30.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                _saveLocation();
              },
              icon: const Icon(
                Icons.location_on,
                color: Colors.black, // Icon color
              ),
              label: const Text(
                'Mark my parking Spot',
                style: TextStyle(color: Colors.white), // Text color
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color.fromARGB(255, 20, 42, 203), // Button color
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            FloatingActionButton(
              onPressed: () {
                _showForm();
              },
              backgroundColor: const Color.fromARGB(255, 20, 42, 203),
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
