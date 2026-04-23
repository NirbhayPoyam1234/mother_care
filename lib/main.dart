import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotherCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.pink),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.data == null) return LoginPage();
            return Dashboard();
          }
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      ),
    );
  }
}

// -------------------- LOGIN PAGE --------------------
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  bool isLogin = true;
  String errorMsg = '';

  Future<void> submit() async {
    setState(() => errorMsg = '');
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email.text.trim(), password: password.text.trim());
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email.text.trim(), password: password.text.trim());
      }
    } on FirebaseAuthException catch (e) {
      setState(() => errorMsg = e.message ?? 'Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.pink[50],
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.favorite, size: 60, color: Colors.pink),
                    SizedBox(height: 20),
                    Text(isLogin ? 'Welcome Back' : 'Create Account',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    SizedBox(height: 30),
                    TextField(controller: email, decoration: InputDecoration(labelText: 'Email')),
                    SizedBox(height: 15),
                    TextField(controller: password, obscureText: true, decoration: InputDecoration(labelText: 'Password')),
                    if (errorMsg.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: Text(errorMsg, style: TextStyle(color: Colors.red)),
                      ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: submit,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, minimumSize: Size(double.infinity, 50)),
                      child: Text(isLogin ? 'Login' : 'Register'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => isLogin = !isLogin),
                      child: Text(isLogin ? 'Need an account? Register' : 'Already have an account? Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------- DASHBOARD --------------------
class Dashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hello ${user?.email?.split('@')[0] ?? 'Mama'}!",
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text("Your pregnancy companion", style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.pink[100],
                    child: IconButton(
                      icon: Icon(Icons.person, color: Colors.pink),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage())),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: EdgeInsets.all(20),
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _menuCard(context, "Health Vitals", Icons.favorite, Colors.pink, HealthPage()),
                  _menuCard(context, "SOS Emergency", Icons.emergency, Colors.red, SOSPage()),
                  _menuCard(context, "Baby Care", Icons.child_care, Colors.teal, BabyCarePage()),
                  _menuCard(context, "Baby Health", Icons.health_and_safety, Colors.orange, BabyHealthPage()),
                  _menuCard(context, "Baby Products", Icons.shopping_bag, Colors.blue, BabyProductsPage()),
                  _menuCard(context, "Maternity Hospitals", Icons.pregnant_woman, Colors.deepPurple, MaternityHospitalsPage()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(BuildContext context, String title, IconData icon, Color color, Widget page) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              SizedBox(height: 12),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- HELPER: RELIABLE LOCATION STRING --------------------
Future<String> getLocationString(BuildContext context) async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enable GPS for location sharing")),
        );
      }
      return "";
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return "";
    }
    if (permission == LocationPermission.deniedForever) return "";

    // Try current position with timeout
    Position? pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: Duration(seconds: 10),
    ).catchError((e) => null);

    pos ??= await Geolocator.getLastKnownPosition();

    if (pos != null) {
      return "\n📍 My location: https://maps.google.com/?q=${pos.latitude},${pos.longitude}";
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not get location. SOS will be without location.")),
        );
      }
      return "";
    }
  } catch (e) {
    print("Location error: $e");
    return "";
  }
}

// -------------------- HELPER: OPEN SMS WITH PRE-FILLED MESSAGE --------------------
Future<void> openSmsWithMessage(String phone, String message) async {
  final Uri smsUri = Uri(scheme: 'sms', path: phone, queryParameters: {'body': message});
  if (await canLaunchUrl(smsUri)) {
    await launchUrl(smsUri);
  } else {
    print("Could not launch SMS for $phone");
  }
}

// -------------------- HEALTH PAGE (Auto SOS for contacts only, opens SMS draft) --------------------
class HealthPage extends StatefulWidget {
  @override
  _HealthPageState createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  DatabaseReference dbRef = FirebaseDatabase.instance.ref("sensors");
  int heartRate = 0;
  int spo2 = 0;

  bool _sosTriggered = false;
  DateTime? _lastSosTime;
  DateTime? _highHeartRateStartTime;
  List<Map<String, dynamic>> _contacts = [];
  User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    dbRef.onValue.listen((event) async {
      var raw = event.snapshot.value;
      if (raw != null && raw is Map) {
        setState(() {
          heartRate = (raw["hr"] ?? 0).toInt();
          spo2 = (raw["spo2"] ?? 0).toInt();
        });

        // Auto SOS only when heart rate > 120 for 30 seconds
        if (heartRate > 120) {
          _highHeartRateStartTime ??= DateTime.now();
          final duration = DateTime.now().difference(_highHeartRateStartTime!).inSeconds;
          if (duration >= 30) {
            await _triggerAutoSOS();
          }
        } else {
          _highHeartRateStartTime = null;
          _sosTriggered = false;
        }
      }
    });
  }

  void _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonStr = prefs.getString('emergency_contacts');
    if (jsonStr != null) {
      setState(() {
        _contacts = List<Map<String, dynamic>>.from(json.decode(jsonStr));
      });
    }
  }

  Future<void> _triggerAutoSOS() async {
    if (_sosTriggered) return;
    if (_lastSosTime != null && DateTime.now().difference(_lastSosTime!).inMinutes < 5) return;

    _sosTriggered = true;
    _lastSosTime = DateTime.now();

    String locationMsg = await getLocationString(context);
    String alert = "🚨 CRITICAL! High heart rate detected for over 30s. HR: $heartRate BPM, SpO2: $spo2%.$locationMsg";

    if (_contacts.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Critical vitals! But no contacts found locally."), backgroundColor: Colors.orange));
      return;
    }

    final Telephony telephony = Telephony.instance;
    bool? permission = await telephony.requestSmsPermissions;

    if (permission == true) {
      for (var c in _contacts) {
        telephony.sendSms(to: c['phone'], message: alert);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("🚨 SOS sent automatically (Vitals disturbed for 30s)"), backgroundColor: Colors.red));
      }
    } else {
      // Fallback
      if (await canLaunchUrl(Uri(scheme: 'sms', path: _contacts[0]['phone'], query: 'body=${Uri.encodeComponent(alert)}'))) {
        await launchUrl(Uri(scheme: 'sms', path: _contacts[0]['phone'], query: 'body=${Uri.encodeComponent(alert)}'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Health Vitals"), backgroundColor: Colors.pink),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _card("Heart Rate", "$heartRate BPM", Icons.favorite, Colors.pink),
            SizedBox(height: 20),
            _card("Blood Oxygen", "$spo2 %", Icons.air, Colors.cyan),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 250,
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 50, color: color),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

// -------------------- PROFILE PAGE (unchanged, works with Firestore) --------------------
class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController nameCtrl = TextEditingController();
  TextEditingController phoneCtrl = TextEditingController();
  TextEditingController bloodCtrl = TextEditingController();
  TextEditingController notesCtrl = TextEditingController();
  TextEditingController addressCtrl = TextEditingController();
  TextEditingController dobCtrl = TextEditingController();

  TextEditingController contactName = TextEditingController();
  TextEditingController contactPhone = TextEditingController();

  User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> contacts = [];

  @override
  void initState() {
    super.initState();
    loadUserData();
    loadContacts();
  }

  void loadUserData() async {
    if (user == null) return;
    var doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    if (doc.exists) {
      var data = doc.data()!;
      nameCtrl.text = data['name'] ?? '';
      phoneCtrl.text = data['phone'] ?? '';
      bloodCtrl.text = data['bloodGroup'] ?? '';
      notesCtrl.text = data['emergencyNotes'] ?? '';
      addressCtrl.text = data['address'] ?? '';
      if (data['dateOfBirth'] != null) {
        DateTime d = (data['dateOfBirth'] as Timestamp).toDate();
        dobCtrl.text = DateFormat('yyyy-MM-dd').format(d);
      }
    }
  }

  void loadContacts() async {
    if (user == null) return;
    var snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('emergencyContacts')
        .orderBy('createdAt', descending: true)
        .get();
    setState(() {
      contacts = snap.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();
    });
  }

  Future<void> saveProfile() async {
    if (user == null) return;
    try {
      Map<String, dynamic> data = {
        'name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'bloodGroup': bloodCtrl.text.trim(),
        'emergencyNotes': notesCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (dobCtrl.text.isNotEmpty) {
        data['dateOfBirth'] = Timestamp.fromDate(DateFormat('yyyy-MM-dd').parse(dobCtrl.text.trim()));
      }
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set(data, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile saved')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> addContact() async {
    if (contactName.text.isEmpty || contactPhone.text.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('emergencyContacts')
        .add({
      'name': contactName.text.trim(),
      'phone': contactPhone.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    contactName.clear();
    contactPhone.clear();
    loadContacts();
  }

  Future<void> deleteContact(String id) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('emergencyContacts')
        .doc(id)
        .delete();
    loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile"), backgroundColor: Colors.purple, actions: [
        IconButton(icon: Icon(Icons.logout), onPressed: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.popUntil(context, (route) => route.isFirst);
        })
      ]),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(radius: 40, backgroundColor: Colors.purple[200], child: Icon(Icons.person, size: 50)),
            SizedBox(height: 10),
            Text("Email: ${user?.email ?? 'Unknown'}"),
            SizedBox(height: 20),
            _field(nameCtrl, "Full Name", Icons.person),
            _field(bloodCtrl, "Blood Group", Icons.bloodtype),
            _field(dobCtrl, "Due Date (YYYY-MM-DD)", Icons.calendar_today),
            _field(phoneCtrl, "Your Phone", Icons.phone),
            _field(addressCtrl, "Address", Icons.home),
            _field(notesCtrl, "Medical Notes", Icons.notes),
            ElevatedButton(onPressed: saveProfile, child: Text("Save Profile")),
            SizedBox(height: 20),
            Text("Emergency Contacts", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(child: TextField(controller: contactName, decoration: InputDecoration(labelText: "Name"))),
                SizedBox(width: 8),
                Expanded(child: TextField(controller: contactPhone, decoration: InputDecoration(labelText: "Phone"))),
                IconButton(onPressed: addContact, icon: Icon(Icons.add_circle, color: Colors.purple)),
              ],
            ),
            ...contacts.map((c) => Card(
              child: ListTile(
                title: Text(c['name']),
                subtitle: Text(c['phone']),
                trailing: IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => deleteContact(c['id'])),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextField(controller: c, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon))),
    );
  }
}

// -------------------- SOS PAGE (Manual SOS for ambulance + contacts) --------------------
class SOSPage extends StatefulWidget {
  @override
  _SOSPageState createState() => _SOSPageState();
}

class _SOSPageState extends State<SOSPage> {
  User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> contacts = [];
  String ambulance = "102";
  int heartRate = 0;
  int spo2 = 0;

  @override
  void initState() {
    super.initState();
    loadContacts();
    
    // Listen to vitals for inclusion in manual SOS
    FirebaseDatabase.instance.ref("sensors").onValue.listen((event) {
      var raw = event.snapshot.value;
      if (raw != null && raw is Map) {
        if (mounted) {
          setState(() {
            heartRate = (raw["hr"] ?? 0).toInt();
            spo2 = (raw["spo2"] ?? 0).toInt();
          });
        }
      }
    });
  }

  void loadContacts() async {
    var snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('emergencyContacts')
        .get();
    setState(() {
      contacts = snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
    });
  }

  void loadAmbulance() async {
    var doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    if (doc.exists && doc.data()!['ambulance'] != null) {
      setState(() => ambulance = doc.data()!['ambulance'].toString());
    }
  }

  void makeCall(String phone) async {
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> sendManualSOS({bool includeAmbulance = true}) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Getting your location...")));
    String locationMsg = await getLocationString(context);
    
    String vitalInfo = "";
    if (heartRate > 0) {
      vitalInfo = " My Vitals: HR: $heartRate BPM, SpO2: $spo2%.";
    }
    
    String alert = "🚨 SOS! I need help.$vitalInfo$locationMsg";

    // Send to ambulance (manually triggered)
    if (includeAmbulance && ambulance.isNotEmpty) {
      await openSmsWithMessage(ambulance, "Ambulance needed. $alert");
      await Future.delayed(Duration(milliseconds: 500));
    }

    // Send to all contacts
    for (var c in contacts) {
      await openSmsWithMessage(c['phone'], alert);
      await Future.delayed(Duration(milliseconds: 500));
    }

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("SOS opened for ambulance and ${contacts.length} contact(s). Tap SEND."), backgroundColor: Colors.red)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("SOS Emergency"), backgroundColor: Colors.red),
      body: Column(
        children: [
          GestureDetector(
            onTap: () => sendManualSOS(includeAmbulance: true),
            child: Container(
              margin: EdgeInsets.all(30),
              height: 150,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red, boxShadow: [BoxShadow(color: Colors.red, blurRadius: 20)]),
              child: Center(child: Text("SOS", style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold))),
            ),
          ),
          Card(
            margin: EdgeInsets.all(16),
            child: ListTile(
              leading: Icon(Icons.local_hospital, color: Colors.red),
              title: Text("Ambulance: $ambulance"),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: Icon(Icons.call), onPressed: () => makeCall(ambulance)),
                IconButton(icon: Icon(Icons.message), onPressed: () => sendManualSOS(includeAmbulance: true)),
              ]),
            ),
          ),
          Text("Emergency Contacts", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (ctx, i) => Card(
                child: ListTile(
                  title: Text(contacts[i]['name']),
                  subtitle: Text(contacts[i]['phone']),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: Icon(Icons.call), onPressed: () => makeCall(contacts[i]['phone'])),
                    IconButton(icon: Icon(Icons.message), onPressed: () => sendManualSOS(includeAmbulance: false)),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// -------------------- BABY CARE --------------------
class BabyCarePage extends StatelessWidget {
  final Map<String, String> tips = {
    '1 Month': 'Feed regularly, keep clean, tummy time short.',
    '2 Months': 'Continue breastfeeding, first vaccines.',
    '3 Months': 'Longer sleep, talk to baby.',
    '4 Months': 'Second vaccines, avoid screens.',
    '5 Months': 'Teething may start.',
    '6 Months': 'Introduce solid foods, sit with support.',
    '8 Months': 'Finger foods, baby proof home.',
    '10 Months': 'Self-feeding, pull to stand.',
    '1 Year': 'Whole milk, first birthday, MMR vaccine.',
    '2 Years': 'Potty training, brush teeth.',
    '3 Years': 'Preschool readiness, regular dental check.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Baby Care by Age"), backgroundColor: Colors.teal),
      body: ListView(
        children: tips.entries.map((e) => Card(
          margin: EdgeInsets.all(8),
          child: ExpansionTile(title: Text(e.key, style: TextStyle(fontWeight: FontWeight.bold)), children: [Padding(padding: EdgeInsets.all(12), child: Text(e.value))]),
        )).toList(),
      ),
    );
  }
}

// -------------------- BABY HEALTH --------------------
class BabyHealthPage extends StatelessWidget {
  final List<Map<String, String>> diseases = [
    {'name': 'Common Cold', 'symptoms': 'Runny nose, sneezing, mild fever', 'treatment': 'Rest, hydration, saline drops.'},
    {'name': 'Hand, Foot & Mouth', 'symptoms': 'Fever, rash on hands/feet, mouth ulcers', 'treatment': 'Pain relief, soft foods.'},
    {'name': 'Chickenpox', 'symptoms': 'Itchy red spots, fever', 'treatment': 'Calamine lotion, oatmeal baths.'},
    {'name': 'Roseola', 'symptoms': 'High fever then rash', 'treatment': 'Fever management, fluids.'},
    {'name': 'Croup', 'symptoms': 'Barking cough, noisy breathing', 'treatment': 'Steam therapy, cool air.'},
    {'name': 'Bronchiolitis (RSV)', 'symptoms': 'Wheezing, rapid breathing', 'treatment': 'Oxygen, hydration.'},
    {'name': 'Pneumonia', 'symptoms': 'High fever, cough with phlegm', 'treatment': 'Antibiotics, rest.'},
    {'name': 'Ear Infection', 'symptoms': 'Ear pulling, fussiness', 'treatment': 'Pain relievers, antibiotics if needed.'},
    {'name': 'Strep Throat', 'symptoms': 'Sore throat, fever', 'treatment': 'Antibiotics.'},
    {'name': 'UTI', 'symptoms': 'Fever, foul urine', 'treatment': 'Antibiotics.'},
    {'name': 'Stomach Flu', 'symptoms': 'Diarrhea, vomiting', 'treatment': 'Oral rehydration solution.'},
    {'name': 'Constipation', 'symptoms': 'Hard stools', 'treatment': 'More fluids, fiber.'},
    {'name': 'Diaper Rash', 'symptoms': 'Red irritated skin', 'treatment': 'Frequent changes, zinc cream.'},
    {'name': 'Eczema', 'symptoms': 'Dry, itchy patches', 'treatment': 'Moisturizers, mild steroids.'},
    {'name': 'Cradle Cap', 'symptoms': 'Scaly patches on scalp', 'treatment': 'Baby oil, gentle brushing.'},
    {'name': 'Thrush', 'symptoms': 'White patches on tongue', 'treatment': 'Antifungal drops.'},
    {'name': 'Measles', 'symptoms': 'High fever, red rash', 'treatment': 'Supportive care, vaccine.'},
    {'name': 'Mumps', 'symptoms': 'Swollen cheeks, fever', 'treatment': 'Rest, fluids.'},
    {'name': 'Rubella', 'symptoms': 'Mild fever, pink rash', 'treatment': 'Supportive care.'},
    {'name': 'Whooping Cough', 'symptoms': 'Severe coughing fits', 'treatment': 'Antibiotics, vaccine.'},
    {'name': 'Scarlet Fever', 'symptoms': 'Sore throat, sandpaper rash', 'treatment': 'Antibiotics.'},
    {'name': 'Kawasaki Disease', 'symptoms': 'High fever >5 days, red eyes', 'treatment': 'IVIG, aspirin.'},
    {'name': 'Reye’s Syndrome', 'symptoms': 'Vomiting, confusion after aspirin', 'treatment': 'Emergency, never give aspirin.'},
    {'name': 'Febrile Seizures', 'symptoms': 'Convulsions with fever', 'treatment': 'Lay child on side, call doctor.'},
    {'name': 'Meningitis', 'symptoms': 'High fever, stiff neck', 'treatment': 'Medical emergency.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Baby Health Guide"), backgroundColor: Colors.orange),
      body: ListView(
        children: diseases.map((d) => Card(
          margin: EdgeInsets.all(8),
          child: ExpansionTile(
            title: Text(d['name']!, style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Padding(padding: EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Symptoms: ${d['symptoms']}"),
                SizedBox(height: 8),
                Text("Treatment: ${d['treatment']}"),
              ])),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

// -------------------- BABY PRODUCTS --------------------
class BabyProductsPage extends StatefulWidget {
  @override
  _BabyProductsPageState createState() => _BabyProductsPageState();
}

class _BabyProductsPageState extends State<BabyProductsPage> {
  List<Map<String, String>> products = [
    {'name': 'Diapers', 'category': 'Essentials', 'search': 'baby diapers'},
    {'name': 'Baby Wipes', 'category': 'Essentials', 'search': 'baby wipes'},
    {'name': 'Crib', 'category': 'Furniture', 'search': 'baby crib'},
    {'name': 'Stroller', 'category': 'Gear', 'search': 'baby stroller'},
    {'name': 'Car Seat', 'category': 'Safety', 'search': 'baby car seat'},
    {'name': 'Baby Monitor', 'category': 'Electronics', 'search': 'baby monitor'},
    {'name': 'Breast Pump', 'category': 'Feeding', 'search': 'breast pump'},
    {'name': 'Baby Bottle', 'category': 'Feeding', 'search': 'baby bottle'},
    {'name': 'High Chair', 'category': 'Furniture', 'search': 'baby high chair'},
    {'name': 'Teething Toy', 'category': 'Toys', 'search': 'teething toy'},
  ];

  Set<String> selected = {};

  void toggle(String name) {
    setState(() {
      if (selected.contains(name)) selected.remove(name);
      else selected.add(name);
    });
  }

  void buy(String query) async {
    String url = "https://www.flipkart.com/search?q=${Uri.encodeComponent(query)}";
    if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Baby Registry"), backgroundColor: Colors.blue),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (ctx, i) {
                var p = products[i];
                return Card(
                  child: ListTile(
                    title: Text(p['name']!),
                    subtitle: Text(p['category']!),
                    leading: Checkbox(value: selected.contains(p['name']), onChanged: (_) => toggle(p['name']!)),
                    trailing: IconButton(icon: Icon(Icons.shopping_cart), onPressed: () => buy(p['search']!)),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
             onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(
              title: Text("My Registry"), content: Text(selected.isEmpty ? "None" : selected.join("\n")),
            )),
            child: Text("View Registry (${selected.length})"),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}

// -------------------- MATERNITY HOSPITALS --------------------
class MaternityHospitalsPage extends StatefulWidget {
  @override
  _MaternityHospitalsPageState createState() => _MaternityHospitalsPageState();
}

class _MaternityHospitalsPageState extends State<MaternityHospitalsPage> {
  bool loading = true;
  List<Map<String, dynamic>> hospitals = [];
  String error = '';
  double? myLat, myLng;

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  Future<void> getLocation() async {
    setState(() => loading = true);
    LocationPermission perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      setState(() { error = 'Location permission denied'; loading = false; });
      return;
    }
    try {
      Position pos = await Geolocator.getCurrentPosition();
      myLat = pos.latitude;
      myLng = pos.longitude;
      await fetchHospitals();
    } catch (e) {
      setState(() { error = 'Could not get location'; loading = false; });
    }
  }

  Future<void> fetchHospitals() async {
    List<int> radii = [3000, 5000, 10000];
    List<Map<String, dynamic>> results = [];

    for (int r in radii) {
      String query = """
        [out:json][timeout:25];
        (
          node["amenity"~"hospital|clinic"](around:$r,$myLat,$myLng);
          way["amenity"~"hospital|clinic"](around:$r,$myLat,$myLng);
          rel["amenity"~"hospital|clinic"](around:$r,$myLat,$myLng);
          node["healthcare"~"hospital|clinic"](around:$r,$myLat,$myLng);
          way["healthcare"~"hospital|clinic"](around:$r,$myLat,$myLng);
          rel["healthcare"~"hospital|clinic"](around:$r,$myLat,$myLng);
        );
        out center;
      """;
      try {
        var response = await http.post(
          Uri.parse("https://overpass-api.de/api/interpreter"),
          headers: {'User-Agent': 'MotherCareApp/1.0', 'Accept': 'application/json'},
          body: {'data': query},
        ).timeout(Duration(seconds: 15));
        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          for (var elem in data['elements']) {
            double lat = elem['lat'] ?? elem['center']?['lat'] ?? 0;
            double lon = elem['lon'] ?? elem['center']?['lon'] ?? 0;
            if (lat == 0 || lon == 0) continue;
            var tags = elem['tags'] ?? {};
            String name = tags['name'] ?? 'Hospital';
            double dist = Geolocator.distanceBetween(myLat!, myLng!, lat, lon) / 1000;
            if (dist > 10) continue;
            bool isMaternity = name.toLowerCase().contains('maternity') ||
                name.toLowerCase().contains('women') ||
                name.toLowerCase().contains('mother') ||
                name.toLowerCase().contains('child') ||
                (tags['healthcare'] ?? '').toString().toLowerCase().contains('obstetric');
            if (isMaternity && !results.any((h) => h['lat'] == lat && h['lon'] == lon)) {
              results.add({
                'name': name,
                'lat': lat,
                'lon': lon,
                'distance': dist,
                'phone': tags['phone'] ?? tags['contact:phone'] ?? '',
                'open': tags['opening_hours'] ?? 'Open 24 hours',
              });
            }
          }
        }
      } catch (e) {}
      if (results.length >= 10) break;
    }
    results.sort((a, b) => a['distance'].compareTo(b['distance']));
    if (!mounted) return;
    setState(() {
      hospitals = results;
      loading = false;
      if (hospitals.isEmpty) error = 'No maternity hospitals found within 10km.';
    });
  }

  void navigate(double lat, double lon) async {
    await launchUrl(Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$lat,$lon"));
  }

  void call(String phone) async {
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Maternity Hospitals"), backgroundColor: Colors.deepPurple, actions: [
        IconButton(icon: Icon(Icons.refresh), onPressed: getLocation),
      ]),
      body: loading ? Center(child: CircularProgressIndicator())
          : error.isNotEmpty ? Center(child: Column(children: [Text(error), ElevatedButton(onPressed: getLocation, child: Text("Retry"))]))
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: hospitals.length,
        itemBuilder: (ctx, i) {
          var h = hospitals[i];
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            child: ListTile(
              title: Text(h['name'], style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("${h['distance'].toStringAsFixed(1)} km away"),
                Text(h['open'], style: TextStyle(fontSize: 12)),
              ]),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (h['phone'].isNotEmpty) IconButton(icon: Icon(Icons.call), onPressed: () => call(h['phone'])),
                IconButton(icon: Icon(Icons.directions), onPressed: () => navigate(h['lat'], h['lon'])),
              ]),
            ),
          );
        },
      ),
    );
  }
}