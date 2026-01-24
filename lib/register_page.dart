import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // For Uint8List
import 'dart:ui' as ui;   // For instantiateImageCodec
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';   // 👈 ADD THIS
import 'globals.dart' as globals;
import 'login_screen.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final nameCtrl = TextEditingController();
  final mobCtrl = TextEditingController();
  final whatsappCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final streetCtrl = TextEditingController();
  final landmarkCtrl = TextEditingController();
  final pincodeCtrl = TextEditingController();
  final districtCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final aadharCtrl = TextEditingController();
  final panCtrl = TextEditingController();
  final bankCtrl = TextEditingController();
  final ifscCtrl = TextEditingController();
  final branchCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final rePasswordCtrl = TextEditingController();

  String? gender, state, profession, maritalStatus;
  DateTime? birthDate;

  bool sameWhatsapp = false;
  bool isLoading = false;

  String? aadharFront;
  String? aadharBack;
  String? panFront;
  String? passportPhoto;

// Server filenames (what PHP returns after upload)
  String? aadharFrontServer;
  String? aadharBackServer;
  String? panFrontServer;
  String? passportPhotoServer;

  // ---------- IMAGE PICKER ----------
  // ---------- IMAGE PICKER ----------
  Future<String?> _pickCompressAndUpload() async {
    print("📸 PICKER called...");
    final picker = ImagePicker();

    // Show choice (camera/gallery)
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Camera"),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Gallery"),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return null;

    final XFile? picked = await picker.pickImage(source: source);
    if (picked == null) return null;

    final origBytes = await picked.readAsBytes();

    // Decode to get original size
    final codec = await instantiateImageCodec(origBytes);
    final frame = await codec.getNextFrame();
    final origW = frame.image.width;
    final origH = frame.image.height;

    // ✅ Target width = 550, compute height keeping aspect ratio
    const int targetW = 550;
    final int targetH = ((origH * targetW) / origW).round().clamp(1, 100000);

    // Compress + resize
    Uint8List resized = (await FlutterImageCompress.compressWithList(
      origBytes,
      format: CompressFormat.jpeg,
      minWidth: targetW,
      minHeight: targetH,
      quality: 85,
    )) as Uint8List;

    // Save to temp file
    final dir = await getTemporaryDirectory();
    final path = "${dir.path}/reg_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final file = File(path);
    await file.writeAsBytes(resized as List<int>, flush: true);
    print("✅ Resized path: ${file.path} (W:$targetW H:$targetH)");

    // 🔹 Upload right away
    final serverFile = await _uploadFile(file.path);
    print("☁️ Uploaded to server: $serverFile");

    return serverFile; // return server-side filename
  }










  Future<String?> _uploadFile(String filePath) async {
    print("🚀 _uploadFile CALLED with: $filePath");   // <---- add this
    try {
      final uri = Uri.parse("${globals.baseIp}/native_app/upload_call_file.php");
      print("🌐 Uploading to $uri");

      var request = http.MultipartRequest("POST", uri);

      request.files.add(
        await http.MultipartFile.fromPath(
          "image",
          filePath,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      var response = await request.send();
      final body = await response.stream.bytesToString();
      print("📩 UPLOAD RAW RESPONSE: $body");

      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        if (data["success"] == true) {
          print("✅ Uploaded: ${data['uploaded_files'][0]}");
          return data["uploaded_files"][0];
        } else {
          print("❌ Server rejected: ${data['message']}");
        }
      } else {
        print("❌ HTTP error: ${response.statusCode}");
      }
    } catch (e) {
      print("🔥 Exception in upload: $e");
    }
    return null;
  }



  // ---------- VALIDATIONS ----------
  bool isValidPAN(String pan) =>
      RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(pan);

  bool isValidIFSC(String ifsc) =>
      RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc);

  bool isValidBank(String acc) =>
      RegExp(r'^[0-9]{9,18}$').hasMatch(acc);

  // ---------- SAVE ----------
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordCtrl.text != rePasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    // ✅ Ensure all uploads done before save
    if ([aadharFrontServer, aadharBackServer, panFrontServer, passportPhotoServer].contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload all mandatory files before saving")),
      );
      return;
    }

    setState(() => isLoading = true);

    final uri = Uri.parse("${globals.baseIp}/native_app/reg.php?subject=reg&action=save");
    final response = await http.post(uri, body: {
      "name": nameCtrl.text,
      "gender": gender ?? "",
      "birth_date": birthDate?.toIso8601String().split("T").first ?? "",
      "mob": mobCtrl.text,
      "whatsapp": whatsappCtrl.text,
      "email": emailCtrl.text,
      "permanent_address": addressCtrl.text,
      "street_name": streetCtrl.text,
      "landmark": landmarkCtrl.text,
      "pincode": pincodeCtrl.text,
      "state": state ?? "",
      "district": districtCtrl.text,
      "city": cityCtrl.text,
      "profession": profession ?? "",
      "marital_status": maritalStatus ?? "",
      "aadhar_num": aadharCtrl.text,
      "aadhar_front": aadharFrontServer!,   // ✅ only filename
      "aadhar_back": aadharBackServer!,
      "pan_num": panCtrl.text,
      "pan_front": panFrontServer!,
      "bank_acc_num": bankCtrl.text,
      "ifsc_code": ifscCtrl.text,
      "branch_name": branchCtrl.text,
      "img_url": passportPhotoServer!,
      "password": passwordCtrl.text,
    });

    final data = jsonDecode(response.body);
    setState(() => isLoading = false);

    if (data["status"] == true) {
      showDialog(
        context: context,
        barrierDismissible: false, // prevent dismiss by tapping outside
        builder: (_) => AlertDialog(
          title: const Text("Success"),
          content: const Text(
            "Your profile has been created successfully.\n\n"
                "It will be verified within 48 hours and you will be notified once the process is complete.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()), // ✅ redirect
                );
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "Error occurred")),
      );
    }
  }


  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final baseColor = const Color(0xFF04649c);
    final accentYellow = const Color(0xFFc68d07);

    final states = [
      "Andhra Pradesh","Arunachal Pradesh","Assam","Bihar","Chhattisgarh","Goa",
      "Gujarat","Haryana","Himachal Pradesh","Jharkhand","Karnataka","Kerala",
      "Madhya Pradesh","Maharashtra","Manipur","Meghalaya","Mizoram","Nagaland",
      "Odisha","Punjab","Rajasthan","Sikkim","Tamil Nadu","Telangana","Tripura",
      "Uttar Pradesh","Uttarakhand","West Bengal","Andaman & Nicobar Islands",
      "Chandigarh","Dadra & Nagar Haveli","Daman & Diu","Delhi","Jammu & Kashmir",
      "Ladakh","Lakshadweep","Puducherry"
    ];

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Register", style: TextStyle(color: Colors.white),),
          backgroundColor: baseColor,
          iconTheme: const IconThemeData(color: Colors.white), // ✅ back arrow white
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name *"), validator: (v) => v!.isEmpty ? "Enter Name" : null),
                DropdownButtonFormField(value: gender, decoration: const InputDecoration(labelText: "Gender *"), items: ["Male","Female","Others"].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(), onChanged:(v)=>setState(()=>gender=v), validator:(v)=>v==null?"Select Gender":null),
                TextFormField(readOnly:true, decoration: const InputDecoration(labelText:"Date of Birth *"), controller: TextEditingController(text: birthDate==null?"":"${birthDate!.day}-${birthDate!.month}-${birthDate!.year}"), onTap:() async{final date=await showDatePicker(context:context, initialDate:DateTime(2000), firstDate:DateTime(1900), lastDate:DateTime.now()); if(date!=null)setState(()=>birthDate=date);}, validator:(v)=>v!.isEmpty?"Select DOB":null),
                TextFormField(controller: mobCtrl, keyboardType: TextInputType.number, maxLength:10, decoration: const InputDecoration(labelText:"Mobile Number *",helperText:"Also used as Login ID"), validator:(v)=>v!.length!=10?"Enter 10-digit number":null),
                Row(children:[Checkbox(value:sameWhatsapp,onChanged:(v){setState(()=>sameWhatsapp=v!); if(v!) whatsappCtrl.text=mobCtrl.text;}),const Text("Same on Whatsapp")]),
                TextFormField(controller: whatsappCtrl, keyboardType: TextInputType.number, maxLength:10, decoration: const InputDecoration(labelText:"Whatsapp *"), validator:(v)=>v!.length!=10?"Enter 10-digit number":null),
                TextFormField(controller: emailCtrl, decoration: const InputDecoration(labelText:"Email ID *"), validator:(v)=>v!.isEmpty?"Enter Email":null),
                TextFormField(controller: addressCtrl, maxLines:2, decoration: const InputDecoration(labelText:"Permanent Address *"), validator:(v)=>v!.isEmpty?"Enter Address":null),
                TextFormField(controller: streetCtrl, decoration: const InputDecoration(labelText:"Street Name *"), validator:(v)=>v!.isEmpty?"Enter Street":null),
                TextFormField(controller: landmarkCtrl, decoration: const InputDecoration(labelText:"Landmark")),
                TextFormField(controller: pincodeCtrl, keyboardType: TextInputType.number, maxLength:6, decoration: const InputDecoration(labelText:"Pin Code *"), validator:(v)=>v!.length!=6?"Enter 6-digit Pin":null),
                DropdownButtonFormField(value: state, decoration: const InputDecoration(labelText: "State *"), items: states.map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(), onChanged:(v)=>setState(()=>state=v), validator:(v)=>v==null?"Select State":null),
                TextFormField(controller: districtCtrl, decoration: const InputDecoration(labelText:"District *"), validator:(v)=>v!.isEmpty?"Enter District":null),
                TextFormField(controller: cityCtrl, decoration: const InputDecoration(labelText:"City *"), validator:(v)=>v!.isEmpty?"Enter City":null),
                DropdownButtonFormField(value: profession, decoration: const InputDecoration(labelText: "Profession *"), items: ["Fabricator","Plumber"].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(), onChanged:(v)=>setState(()=>profession=v), validator:(v)=>v==null?"Select Profession":null),
                DropdownButtonFormField(value: maritalStatus, decoration: const InputDecoration(labelText: "Marital Status *"), items: ["Single","Married","Divorced","Widowed"].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(), onChanged:(v)=>setState(()=>maritalStatus=v), validator:(v)=>v==null?"Select Status":null),
                TextFormField(controller: aadharCtrl, keyboardType: TextInputType.number, maxLength:12, decoration: const InputDecoration(labelText:"Aadhar Number *"), validator:(v)=>v!.length!=12?"Enter 12-digit Aadhaar":null),
      
                // Upload buttons




                // Aadhaar Front
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        print("👉 Aadhaar Front Button pressed");
                        final uploaded = await _pickCompressAndUpload();
                        if (uploaded != null) {
                          setState(() {
                            aadharFrontServer = uploaded;   // ✅ server filename
                          });
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        aadharFrontServer == null
                            ? "Upload Aadhaar Front"
                            : "✅ Aadhaar Front Uploaded",
                      ),
                    ),
                    if (aadharFrontServer != null) ...[
                      const SizedBox(height: 8),
                      Image.network(
                        "${globals.baseIp}/upload_image/$aadharFrontServer",
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ],
                  ],
                ),

// Aadhaar Back
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        print("👉 Aadhaar Back Button pressed");
                        final uploaded = await _pickCompressAndUpload();
                        if (uploaded != null) {
                          setState(() {
                            aadharBackServer = uploaded;
                          });
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        aadharBackServer == null
                            ? "Upload Aadhaar Back"
                            : "✅ Aadhaar Back Uploaded",
                      ),
                    ),
                    if (aadharBackServer != null) ...[
                      const SizedBox(height: 8),
                      Image.network(
                        "${globals.baseIp}/upload_image/$aadharBackServer",
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ],
                  ],
                ),

// PAN Front
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        print("👉 PAN Front Button pressed");
                        final uploaded = await _pickCompressAndUpload();
                        if (uploaded != null) {
                          setState(() {
                            panFrontServer = uploaded;
                          });
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        panFrontServer == null
                            ? "Upload PAN Front"
                            : "✅ PAN Front Uploaded",
                      ),
                    ),
                    if (panFrontServer != null) ...[
                      const SizedBox(height: 8),
                      Image.network(
                        "${globals.baseIp}/upload_image/$panFrontServer",
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ],
                  ],
                ),

// Passport Photo
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        print("👉 Passport Photo Button pressed");
                        final uploaded = await _pickCompressAndUpload();
                        if (uploaded != null) {
                          setState(() {
                            passportPhotoServer = uploaded;
                          });
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        passportPhotoServer == null
                            ? "Upload Passport Photo"
                            : "✅ Passport Photo Uploaded",
                      ),
                    ),
                    if (passportPhotoServer != null) ...[
                      const SizedBox(height: 8),
                      Image.network(
                        "${globals.baseIp}/upload_image/$passportPhotoServer",
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ],
                  ],
                ),



















                TextFormField(controller: panCtrl, maxLength:10, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText:"PAN Number *"), validator:(v)=>!isValidPAN(v!)?"Invalid PAN":null),




                TextFormField(controller: bankCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:"Bank Account Number *"), validator:(v)=>!isValidBank(v!)?"Enter valid Bank Account":null),
                TextFormField(controller: ifscCtrl, maxLength:11, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText:"IFSC Code *"), validator:(v)=>!isValidIFSC(v!)?"Invalid IFSC":null),
                TextFormField(controller: branchCtrl, decoration: const InputDecoration(labelText:"Branch Name *"), validator:(v)=>v!.isEmpty?"Enter Branch":null),




                TextFormField(controller: passwordCtrl, obscureText:true, decoration: const InputDecoration(labelText:"Password *"), validator:(v)=>v!.length<6?"Min 6 chars":null),
                TextFormField(controller: rePasswordCtrl, obscureText:true, decoration: const InputDecoration(labelText:"Re-type Password *"), validator:(v)=>v!.length<6?"Min 6 chars":null),
      
                const SizedBox(height:20),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentYellow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: _save,
                  child: const Text("SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
