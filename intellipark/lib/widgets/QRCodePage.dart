import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart'; // Confirm that this import is correct

class QRCodePage extends StatelessWidget {
  final String qrData; // Declare qrData as a member of QRCodePage

  const QRCodePage({
    super.key,
    required this.qrData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code'),
      ),
      body: Center(
        // Center the main content area
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment
                .center, // Center along the main axis (vertical)
            crossAxisAlignment: CrossAxisAlignment
                .center, // Center along the cross axis (horizontal)
            children: [
              Text(
                'Scan the code to view details', // Instructional text
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20), // Space between the text and QR code
              if (qrData.isNotEmpty) // Check if qrData is not empty
                PrettyQr(
                    data: qrData,
                    size: 200, // Define the size of the QR code
                    roundEdges: true // Optional rounded edges for aesthetics
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
