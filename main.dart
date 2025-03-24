import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IUGB AUTHENTICATOR',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        useMaterial3: true,
      ),
      home: const StudentInfoPage(),
    );
  }
}

class StudentInfoPage extends StatefulWidget {
  const StudentInfoPage({super.key});

  @override
  State<StudentInfoPage> createState() => _StudentInfoPageState();
}

class _StudentInfoPageState extends State<StudentInfoPage> {
  final TextEditingController _studentIdController = TextEditingController();
  Map<String, dynamic>? studentInfo;
  bool isLoading = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QRScannerPage(
                    onQRCodeScanned: (String code) {
                      _studentIdController.text = code;
                      fetchStudentInfo(code);
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _studentIdController,
                      decoration: const InputDecoration(
                        labelText: 'Enter ID Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                        suffixIcon: Icon(Icons.qr_code_scanner),
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          fetchStudentInfo(value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_studentIdController.text.isNotEmpty) {
                          fetchStudentInfo(_studentIdController.text);
                        }
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('Search Student'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage != null)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (studentInfo != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: studentInfo!['photo'] != null
                              ? Image.network(
                                  studentInfo!['photo'],
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.blue,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Error loading image: $error');
                                    return const Icon(Icons.person, size: 80, color: Colors.blue);
                                  },
                                )
                              : const Icon(Icons.person, size: 80, color: Colors.blue),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${studentInfo!['firstname']} ${studentInfo!['lastname']}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow(Icons.badge, 'Student ID', studentInfo!['id']),
                      _buildInfoRow(Icons.email, 'Email', studentInfo!['email']),
                      _buildInfoRow(Icons.school, 'Major', studentInfo!['major']),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> fetchStudentInfo(String id) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      studentInfo = null;
    });

    try {
      print('Fetching student info for ID: $id');
      final response = await http.get(
        Uri.parse('http://192.168.1.12:5000/students/$id'),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please check if the server is running.');
        },
      );

      if (response.statusCode == 200) {
        final student = json.decode(response.body);
        print('Received student data: $student');
        setState(() {
          studentInfo = student;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          errorMessage = 'Student ID not found in database';
        });
      } else if (response.statusCode == 500) {
        setState(() {
          errorMessage = 'Database error. Please check if MySQL is running.';
        });
      } else {
        setState(() {
          errorMessage = 'Failed to fetch student information: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Error occurred: $e');
      setState(() {
        errorMessage = 'Error connecting to server. Please check if:\n1. The server is running\n2. You are connected to the correct network\n3. The IP address is correct';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    super.dispose();
  }
}

class QRScannerPage extends StatefulWidget {
  final Function(String) onQRCodeScanned;

  const QRScannerPage({
    super.key,
    required this.onQRCodeScanned,
  });

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
        overlay: QrScannerOverlayShape(
          borderColor: Colors.blue,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 300,
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!isScanned && scanData.code != null) {
        isScanned = true;
        widget.onQRCodeScanned(scanData.code!);
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
} 