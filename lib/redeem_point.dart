// redeem_point.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'home_page.dart';
import 'globals.dart' as globals;

class RedeemPoint extends StatefulWidget {
  const RedeemPoint({super.key});

  @override
  State<RedeemPoint> createState() => _RedeemPointState();
}

class _RedeemPointState extends State<RedeemPoint> {
  String? presentPointCollected;
  String? redeemProcess;
  String? minAmt;
  String? userId;
  String? mob;
  String? name;

  final TextEditingController _amtController = TextEditingController();
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      presentPointCollected = prefs.getString('presentPointCollected') ?? "0";
      redeemProcess = prefs.getString('redeemProcess') ?? "0";
      minAmt = prefs.getString('minAmt') ?? "0";
      userId = prefs.getString('user_id') ?? "";
      mob = prefs.getString('mob') ?? "";
      name = prefs.getString('name') ?? "";
    });
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

  Future<void> _applyRedeem(BuildContext context) async {
    final amt = _amtController.text.trim();
    if (amt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a redeem amount.")),
      );
      return;
    }

    // ✅ Convert values to int
    final present = int.tryParse(presentPointCollected ?? "0") ?? 0;
    final redeemProc = int.tryParse(redeemProcess ?? "0") ?? 0;
    final inputAmt = int.tryParse(amt) ?? 0;
    final minAmtInt = int.tryParse(minAmt ?? "0") ?? 0;

    if (inputAmt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid redeem amount.")),
      );
      return;
    }

    // ✅ Validation: cannot exceed available and must meet min amount
    if (present < (redeemProc + inputAmt) || inputAmt < minAmtInt) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Entered amount exceeds available balance or below minimum.")),
      );
      return;
    }

    setState(() => isProcessing = true);

    try {
      // ---------- Get location ----------
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

      // ---------- Call Redeem Apply API ----------
      final apiUrl = Uri.parse(
          "${globals.baseIp}/native_app/redeem_apply.php?subject=redeem&action=apply");

      final apiResponse = await http.post(apiUrl, body: {
        "user_id": userId ?? "",
        "mob": mob ?? "",
        "name": name ?? "",
        "lat": pos.latitude.toString(),
        "lon": pos.longitude.toString(),
        "loc_address": address,
        "amt": amt,
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
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text(
          "Redeem Point",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFed1c24),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // ✅ Present Point Info
            Text(
              "Present Point Collected : ${presentPointCollected ?? '...'}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0E4374),
              ),
            ),
            const SizedBox(height: 20),

            // ✅ Textbox
            TextField(
              controller: _amtController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Enter Point For Redeem",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              ),
            ),
            const SizedBox(height: 20),

            // ✅ Apply Button
            GestureDetector(
              onTap: () {
                _applyRedeem(context);
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
                    "APPLY REDEEM",
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
