import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  Future<void> _login(String email, String password) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response = await http.post(
      Uri.parse('https://intellipark-430801.nw.r.appspot.com/login'),
      headers: {'Content-Type': 'application/json'},
      body:
          jsonEncode({'email': email.toLowerCase(), 'passwordHash': password}),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      final token = responseData['token'];
      final user = responseData['user']; // assuming user data is in response
      final userRole = user['role']; // extracting the user's role

      // Save the token and user data to shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('authToken', token);
      await prefs.setString(
          'userData', jsonEncode(user)); // Store user data as JSON

      // Navigate to the relevant page based on the user's role
      if (userRole == 'admin') {
        Navigator.pushNamedAndRemoveUntil(
            context, '/admin', (Route<dynamic> route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(
            context, '/home', (Route<dynamic> route) => false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email or password')),
      );
    }
  }

  void sendEmailRequest() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'admin@intelliparkAshesi.com',
      query: encodeQueryParameters(<String, String>{
        'subject': 'Request to Create an Account',
        'body':
            'I am writing this mail to request an account be created for me in the IntelliPark system.\n\nThank you.\n\nBest Regards,\n[Your Name]'
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
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IntelliPark',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              constraints: const BoxConstraints.expand(),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 240, 240, 242),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 150),
                      Image.asset(
                        'assets/images/parkingicon.png',
                        width: 200,
                        height: 200,
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your email';
                          } else if (!value.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () =>
                                setState(() => _obscureText = !_obscureText),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            const Color.fromARGB(255, 46, 63, 245),
                          ),
                          foregroundColor: MaterialStateProperty.all<Color>(
                            Colors.white,
                          ),
                        ),
                        onPressed: () {
                          _login(
                              _emailController.text, _passwordController.text);
                        },
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Login',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                      const SizedBox(height: 100),
                      Center(
                        child: InkWell(
                          onTap: () {
                            sendEmailRequest();
                          },
                          child: const Text.rich(
                            TextSpan(
                              text: "Don't Have an Account? ",
                              children: [
                                TextSpan(
                                  text:
                                      'Contact your institution administrator to create an account',
                                  style: TextStyle(
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
