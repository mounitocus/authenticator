import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Information System',
      theme: ThemeData(primarySwatch: Colors.blue),
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
        title: const Text('Student Information'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () async {
              String? scannedId = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QRScannerPage()),
              );
              if (scannedId != null) {
                _studentIdController.text = scannedId;
                fetchStudentInfo(scannedId);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _studentIdController,
              decoration: const InputDecoration(
                labelText: 'Enter Student ID',
                border: OutlineInputBorder(),
              ),
              onSubmitted: fetchStudentInfo,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => fetchStudentInfo(_studentIdController.text),
              child: const Text('Search Student'),
            ),
            const SizedBox(height: 20),
            if (isLoading) const CircularProgressIndicator(),
            if (errorMessage != null)
              Text(errorMessage!, style: const TextStyle(color: Colors.red)),
            if (studentInfo != null) ...[
              Text('Full Name: ${studentInfo!['fullname']}'),
              Text('Study Area: ${studentInfo!['study_area']}'),
              Text('Degree Year: ${studentInfo!['degree_year']}'),
              Image.network(
                studentInfo!['studentphoto'],
                height: 100,
                width: 100,
              ),
            ],
          ],
        ),
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
      final response = await http.get(
        Uri.parse('http://localhost:3001/student?idnumber=$id'),
      );

      if (response.statusCode == 200) {
        setState(() {
          studentInfo = json.decode(response.body);
        });
      } else {
        setState(() {
          errorMessage = 'Student not found';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error connecting to server';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? scannedResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
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
      if (scanData.code != null) {
        Navigator.pop(context, scanData.code);
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
