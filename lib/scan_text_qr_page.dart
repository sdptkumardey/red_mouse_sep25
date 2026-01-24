// scan_text_qr_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'scan_camera_qr_page.dart'; // For Scan Now navigation
import 'globals.dart' as globals;

class ScanTextQrPage extends StatefulWidget {
  const ScanTextQrPage({super.key});

  @override
  State<ScanTextQrPage> createState() => _ScanTextQrPageState();
}

class _ScanTextQrPageState extends State<ScanTextQrPage> {
  final TextEditingController _qrController = TextEditingController();
  bool isProcessing = false;

  // ✅ Handle location permission
  Future<bool> _handleLocationPermission(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled.")),
      );
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permissions are denied.")),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Location permissions are permanently denied. Enable from settings."),
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _processQrCode(String qrCode, BuildContext context) async {
    if (isProcessing) return;
    setState(() => isProcessing = true);

    try {
      // ---------- Get stored user data ----------
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id") ?? "";
      final mob = prefs.getString("mob") ?? "";
      final name = prefs.getString("name") ?? "";

      // ---------- Check & Get location ----------
      final hasPermission = await _handleLocationPermission(context);
      if (!hasPermission) {
        setState(() => isProcessing = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode
      final url = Uri.parse(
          "https://nominatim.openstreetmap.org/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=json");

      final response = await http.get(url, headers: {
        "User-Agent": "CredSepApp/1.0 (contact@yourdomain.com)"
      });

      String address = "Unknown";
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        address = data['display_name'] ?? "Address not found";
      }

      // ---------- Call API ----------
      final apiUrl = Uri.parse(
          "${globals.baseIp}/native_app/qr_scan.php?subject=qr&action=scan");

      final apiResponse = await http.post(apiUrl, body: {
        "user_id": userId,
        "mob": mob,
        "name": name,
        "lat": pos.latitude.toString(),
        "lon": pos.longitude.toString(),
        "loc_address": address,
        "qr_code": qrCode,
      });

      final result = jsonDecode(apiResponse.body);
      final bool status = result["status"] ?? false;
      final String message = result["message"] ?? "Something went wrong";

      if (!mounted) return;

      // ---------- Show Alert ----------
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            title: Text(status ? "Success" : "Error"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // close dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const ScanCameraQrPage()),
                  );
                },
                child: const Text("SCAN NOW"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // close dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const ScanTextQrPage()),
                  );
                },
                child: const Text("TYPE QR"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                        (route) => false,
                  );
                },
                child: const Text("HOME PAGE"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ---------- App Bar ----------
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text(
          "Type QR Code",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFed1c24),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // ---------- Page Body ----------
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Text Field
            TextField(
              controller: _qrController,
              decoration: InputDecoration(
                hintText: "Enter QR Code",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 12),
              ),
            ),
            const SizedBox(height: 20),

            // Search Button
            GestureDetector(
              onTap: () {
                final qrCode = _qrController.text.trim();
                if (qrCode.isNotEmpty) {
                  _processQrCode(qrCode, context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter a QR code.")),
                  );
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFfcd985), Color(0xFFfae7bb)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Text(
                    "SEARCH",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0E4374),
                    ),
                  ),
                ),
              ),
            ),

            if (isProcessing) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
