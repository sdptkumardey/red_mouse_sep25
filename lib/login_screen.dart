import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gmpl_tiffin/register_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'forgot_password.dart';
import 'home_page.dart';
import 'globals.dart' as globals;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true; // 👁 password visibility toggle

  @override
  void initState() {
    super.initState();
    _saveIpToPrefs(); // store global IP into prefs once
  }

  Future<void> _saveIpToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("ip", globals.baseIp);
  }

  Future<void> login() async {
    final mob = _mobController.text.trim();
    final password = _passwordController.text;

    if (mob.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter mobile & password')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final ip = prefs.getString('ip') ?? globals.baseIp; // fallback
      final baseUrl = 'http://$ip';

      final response = await http.post(
        Uri.parse(
          "${globals.baseIp}/native_app/login.php?subject=login&action=chk",
        ),
        body: {'mob': mob, 'password': password},
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('name', data['name']);
        await prefs.setString('img_url', data['img_url']);
        await prefs.setString('user_id', data['user_id'].toString());
        await prefs.setString('mob', mob.toString());



        // ✅ Store current date & time in IST
        final nowUtc = DateTime.now().toUtc();
        final indiaTime = nowUtc.add(const Duration(hours: 5, minutes: 30));
        final formattedDateTime =
            "${indiaTime.day.toString().padLeft(2, '0')}-${indiaTime.month.toString().padLeft(2, '0')}-${indiaTime.year} "
            "${indiaTime.hour.toString().padLeft(2, '0')}:${indiaTime.minute.toString().padLeft(2, '0')}";

        await prefs.setString('last_login', formattedDateTime);





        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid login')),
        );
      }
    } catch (e) {
      print('HTTP error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/background7.png"),
            fit: BoxFit.cover, // ✅ covers full screen, no squishing
          ),
        ),
        child: SingleChildScrollView(
          child: Container(
            height: screenHeight, // ✅ force background to full height
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🔷 Logo
                Image.asset('images/logo2.png', height: 150.0),
                const SizedBox(height: 40),

                // 🔷 Title
                const Text(
                  'LOGIN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    color: Color(0xFF0a78b8),
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Enter Mobile Number And Password',
                  style: TextStyle(fontSize: 18, color: Color(0XFFbf8702)),
                ),
                const SizedBox(height: 20),

                // 📱 Mobile Number
                TextField(
                  controller: _mobController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                  ),
                ),
                const SizedBox(height: 15),

                // 🔒 Password with Eye Toggle
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // 🔘 Login Button
                isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: login,
                    icon: const Icon(Icons.login, color: Colors.white),
                    label: const Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFbf8702),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🔗 Forgot Password (text) + Register Now (highlighted)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Forgot Password (Text Button)
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to Forgot Password Page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const Forgotpassword()),
                        );
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: Color(0xFF0a78b8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Register Now (Highlighted like Login Button)
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Navigate to Register Page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0a78b8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        "Register Now",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
