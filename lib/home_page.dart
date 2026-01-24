import 'dart:convert';
import 'package:flutter/material.dart';
import 'change_password_page.dart';
import 'redeem_statement_page.dart';
import 'point_statement.dart';
import 'statement_ledger_page.dart';
import 'scan_qr_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'globals.dart' as globals;
import 'login_screen.dart'; // 👈 import your login page
import 'redeem_point.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? imgUrl;
  String? userName;
  String? lastLogin;
  // 👇 Variables from API
  String? totalPointCollected;  // initially null
  String? totalRedeem;
  String? presentPointCollected;
  String? redeemProcess;
  String? minAmt;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchHomePageData(); // ✅ call API when page loads
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      imgUrl = prefs.getString("img_url");
      userName = prefs.getString("name") ?? "User";
      lastLogin = prefs.getString("last_login") ?? "N/A";
      print("SET IMAGE : ");
      print(imgUrl);
    });
  }


  Future<void> _fetchHomePageData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id") ?? "";
      final mob = prefs.getString("mob") ?? "";

      final apiUrl = Uri.parse(
          "${globals.baseIp}/native_app/home_page.php?subject=home&action=load");

      final response = await http.post(apiUrl, body: {
        "user_id": userId,
        "mob": mob,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == true) {
          setState(() {
            totalPointCollected = data["total_point_collected"].toString();
            totalRedeem = data["total_redeem"].toString();
            presentPointCollected = data["present_point_collected"].toString();
            redeemProcess = data["redeem_process"].toString();
            minAmt = data["min_amt"].toString();
            prefs.setString('totalPointCollected', totalPointCollected!);
            prefs.setString('total_redeem', totalRedeem!);
            prefs.setString('presentPointCollected', presentPointCollected!);
            prefs.setString('redeemProcess', redeemProcess!);
            prefs.setString('minAmt', minAmt!);
          });
        }
      }
    } catch (e) {
      print("Error fetching home page data: $e");
    }
  }


  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // remove all saved data
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Drawer(   // ✅ Drawer added
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFFbf9102)),
                currentAccountPicture: ClipOval(
                  child: imgUrl != null && imgUrl!.isNotEmpty
                      ? Image.network(
                    "${globals.baseIp}/upload_image/$imgUrl", // ✅ prepend baseIp
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => Image.asset("images/45.jpg"),
                  )
                      : Image.asset("images/45.jpg"),
                ),
                accountName: Text(userName ?? "User"),
                accountEmail: Text("Last Login: $lastLogin"),
              ),



              ListTile(
                leading: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                title: const Text("Scan QR Code"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScanQrPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.card_giftcard, color: Colors.green),
                title: const Text("Redeem Point"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RedeemPoint()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart, color: Colors.orange),
                title: const Text("Point Statement"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PointStatementPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.teal),
                title: const Text("Redeem Statement"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RedeemStatementPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: Colors.purple),
                title: const Text("Party Ledger"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StatementLedgerPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_reset, color: Colors.indigo),
                title: const Text("Change Password"),
                onTap: () {
                  print('CHANGE PASSWORD');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
                  );
                },
              ),

              // Divider + spacing before logout
              const SizedBox(height: 10),
              const Divider(thickness: 1.2),
              const SizedBox(height: 10),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Logout"),
                onTap: _logout,
              ),

            ],
          ),
        ),
        body: Column(
         // crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- Header ----------
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFC6CEDF), // same as #c6cedf
                    width: 1.0,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color(0xFFFDB713), // border color
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: imgUrl != null && imgUrl!.isNotEmpty
                          ? Image.network(
                        "${globals.baseIp}/upload_image/$imgUrl",
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            "images/45.jpg",
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                          : Image.asset(
                        "images/45.jpg",
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + Last Login
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hi, ${userName ?? ''}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 14, color: Color(0xFF5C5A59)),
                            const SizedBox(width: 4),
                            Text(
                              "Last Login ${lastLogin ?? ''}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5C5A59),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        Scaffold.of(ctx).openDrawer(); // ✅ opens Drawer
                      },
                    ),
                  ),
                ],
              ),
            ),


            // ---------- Scrollable Content ----------
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 5),
                child: Column(
                  children: [
                    // First Gradient Rectangle Card (p1.png)


                    // ---------- QR Scan Full Width Box ----------
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ScanQrPage()),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 5),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFfcd985), Color(0xFFfae7bb)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Left GIF image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                "images/qr-scan.gif",
                                height: 60,
                                width: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Right text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    "SCAN QR CODE",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0E4374),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "To gain the points",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4F586C),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          ],
                        ),
                      ),
                    ),

                // ---------- Balanced Grid Layout ----------
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 0),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            // Left big rect (Present Point Collected)
                            Expanded(
                              child: Row(
                                children: [
                                  // Left big rect (Rect1)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFfcd985),
                                                Color(0xFFfae7bb)
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: [
                                              const Image(
                                                  image: AssetImage("images/p1.png"),
                                                  height: 80),
                                              const SizedBox(height: 8),
                                              const Text(
                                                "Total Point Collected",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF4F586C),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                totalPointCollected ?? "Loading...",   // ✅ show ... until API value is loaded
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0E4374),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFfcd985),
                                                Color(0xFFfae7bb)
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: [
                                              const Image(
                                                  image: AssetImage("images/p2.png"),
                                                  height: 80),
                                              const SizedBox(height: 8),
                                              const Text(
                                                "Present Point Collected",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF4F586C),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                presentPointCollected ?? "Loading...",   // ✅ show ... until API value is loaded
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0E4374),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 5),

                                  // Right stacked rects (Rect2 + Rect3)
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                              BorderRadius.circular(16),
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFFfcd985),
                                                  Color(0xFFfae7bb)
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                              MainAxisAlignment.center,
                                              children: [
                                                const Image(
                                                    image: AssetImage(
                                                        "images/p3.png"),
                                                    height: 60),
                                                const SizedBox(height: 8),
                                                const Text(
                                                  "Total Redeemed",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF4F586C),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  totalRedeem ?? "Loading...",   // ✅ show ... until API value is loaded
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF0E4374),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                              BorderRadius.circular(16),
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFFfcd985),
                                                  Color(0xFFfae7bb)
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                              MainAxisAlignment.center,
                                              children: [
                                                const Image(
                                                    image: AssetImage(
                                                        "images/p4.png"),
                                                    height: 60),
                                                const SizedBox(height: 8),
                                                const Text(
                                                  "Redeem In Process",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF4F586C),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  redeemProcess ?? "Loading...",   // ✅ show ... until API value is loaded
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF0E4374),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                 //   const SizedBox(height: 5),


                    // ---------- QR Scan Full Width Box ----------
                    if ((int.tryParse(presentPointCollected ?? "0") ?? 0) -
                        (int.tryParse(redeemProcess ?? "0") ?? 0) >=
                        (int.tryParse(minAmt ?? "0") ?? 0))
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RedeemPoint()),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 5),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFfcd985), Color(0xFFfae7bb)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Left GIF image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                "images/redeem.png",
                                height: 60,
                                width: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Right text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children:  [
                                  Text(
                                    "REDEEM POINT",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0E4374),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Minimum point ${minAmt ?? '...'} to apply for redeem",  // ✅ show ... if null
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4F586C),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          ],
                        ),
                      ),
                    ),

                    // ---------- 3 Buttons Row ----------
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                      child: Row(
                        children: [
                          // Button 1
                          Expanded(
                            child: GestureDetector(
                              onTap: (){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const PointStatementPage()),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFfcd985), Color(0xFFfae7bb)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.receipt_long, color: Color(0xFFed1c24), size: 24),
                                    SizedBox(height: 6),
                                    Text(
                                      "Point\nStatement",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0E4374),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Button 2
                          Expanded(
                            child: GestureDetector(
                              onTap: (){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const RedeemStatementPage()),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFfcd985), Color(0xFFfae7bb)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.card_giftcard, color: Color(0xFFed1c24), size: 24),
                                    SizedBox(height: 6),
                                    Text(
                                      "Redeem\nStatement",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0E4374),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Button 3
                          Expanded(
                            child: GestureDetector(
                              onTap: (){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const StatementLedgerPage()),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFfcd985), Color(0xFFfae7bb)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.pending_actions, color: Color(0xFFed1c24), size: 24),
                                    SizedBox(height: 6),
                                    Text(
                                      "Party\nLedger",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0E4374),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),














                  ],
                ),
              ),
            ),







            // ---------- Full Width "View Our Products" Block ----------
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFed1c24), Color(0xFFb3060d)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Color(0xFFb3060d), // border color
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(0), // ✅ no rounded rect
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // ✅ center horizontally
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Image
                  Image.asset(
                    "images/logo3.png",
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),

                  // Right Text
                  const Text(
                    "View Our Products",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),









          ],
        ),
      ),
    );
  }
}
