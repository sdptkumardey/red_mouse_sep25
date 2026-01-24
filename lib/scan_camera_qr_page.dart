import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart'; // your HomePage
import 'globals.dart' as globals;

class ScanCameraQrPage extends StatefulWidget {
  const ScanCameraQrPage({super.key});

  @override
  State<ScanCameraQrPage> createState() => _ScanCameraQrPageState();
}

class _ScanCameraQrPageState extends State<ScanCameraQrPage> {
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _saveIpToPrefs(); // store global IP into prefs once
  }

  Future<void> _saveIpToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("ip", globals.baseIp);
  }

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
      final ip = prefs.getString('ip') ?? globals.baseIp; // fallback
      final baseUrl = 'http://$ip';

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
                  setState(() => isProcessing = false);
                },
                child: const Text("SCAN QR AGAIN !"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // close dialog
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ---------- App Bar ----------
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text(
          "QR Code",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFed1c24),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // ---------- QR Scanner + Frame + Loading Overlay ----------
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (barcodeCapture) {
              final List<Barcode> barcodes = barcodeCapture.barcodes;
              if (barcodes.isNotEmpty) {
                final String qrCode = barcodes.first.rawValue ?? "";
                if (qrCode.isNotEmpty) {
                  _processQrCode(qrCode, context);
                }
              }
            },
          ),

          // ---------- Center Frame Overlay ----------
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Colors.transparent,
              ),
            ),
          ),

          // ---------- Loading Overlay ----------
          if (isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Processing...",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
