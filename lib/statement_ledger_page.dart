import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'globals.dart' as globals;

class StatementLedgerPage extends StatefulWidget {
  const StatementLedgerPage({super.key});

  @override
  State<StatementLedgerPage> createState() => _StatementLedgerPageState();
}

class _StatementLedgerPageState extends State<StatementLedgerPage> {
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  bool isProcessing = false;
  List<dynamic> ledgerList = [];
  int liveBalance = 0;

  @override
  void initState() {
    super.initState();
    _setDefaultDates();
  }

  void _setDefaultDates() {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 30));
    _fromDateController.text =
    "${from.year.toString().padLeft(4, '0')}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}";
    _toDateController.text =
    "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    // auto fetch after setting dates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLedger(context);
    });
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text =
        "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _fetchLedger(BuildContext context) async {
    final fromDate = _fromDateController.text.trim();
    final toDate = _toDateController.text.trim();

    if (fromDate.isEmpty || toDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Both From Date and To Date are required.")),
      );
      return;
    }

    setState(() => isProcessing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id") ?? "";
      final mob = prefs.getString("mob") ?? "";

      final apiUrl = Uri.parse(
          "${globals.baseIp}/native_app/statement_ledger.php?subject=ledger&action=statement");

      final apiResponse = await http.post(apiUrl, body: {
        "user_id": userId,
        "mob": mob,
        "from_date": fromDate,
        "to_date": toDate,
      });

      final result = jsonDecode(apiResponse.body);

      if (result["status"] == true) {
        setState(() {
          ledgerList = result["list"] ?? [];
          liveBalance = result["live_balance"] ?? 0;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result["message"] ?? "No data found.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Widget _buildLedgerItem(Map<String, dynamic> item) {
    final type = item["type"] ?? "";
    final drCr = item["dr_cr"] ?? "";
    final voucherDate = item["voucher_date"] ?? "";

    final processAmt = item["process_amt"] ?? 0;
    final tds = item["tds"] ?? 0;
    final liveBal = item["live_balance"] ?? 0;
    final voucherAmt = item["voucher_amt"] ?? 0;

    final typeColor = drCr == "DR" ? Colors.green : Colors.red;
    final symbol = drCr == "DR" ? "+" : "-";

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.red, width: 1), // red separator
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "$symbol $voucherAmt",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                    fontSize: 14,
                  ),
                ),
                Text(
                  voucherDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
                if (processAmt > 0)
                  Text(
                    "Paid : $processAmt",
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  ),
                if (tds > 0)
                  Text(
                    "TDS : $tds",
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  ),
              ],
            ),
          ),

          // Right side (live balance)
          Text(
            liveBal.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF434c5e),
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fromDate = _fromDateController.text;
    final toDate = _toDateController.text;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Statement Ledger",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFed1c24),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ✅ Row with From Date, To Date, and Search Button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fromDateController,
                    readOnly: true,
                    onTap: () => _selectDate(context, _fromDateController),
                    decoration: InputDecoration(
                      labelText: "From Date",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _toDateController,
                    readOnly: true,
                    onTap: () => _selectDate(context, _toDateController),
                    decoration: InputDecoration(
                      labelText: "To Date",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _fetchLedger(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFfcd985), Color(0xFFfae7bb)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Text(
                      "SEARCH",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0E4374),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ✅ Show selected date range
            if (fromDate.isNotEmpty && toDate.isNotEmpty)
              Text(
                "From $fromDate to $toDate",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0E4374),
                ),
              ),

            const SizedBox(height: 10),

            if (isProcessing) const CircularProgressIndicator(),

            // Ledger List
            if (!isProcessing && ledgerList.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: ledgerList.length,
                  itemBuilder: (ctx, i) =>
                      _buildLedgerItem(ledgerList[i] as Map<String, dynamic>),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
