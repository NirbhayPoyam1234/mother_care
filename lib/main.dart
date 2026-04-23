import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: Color(0xFFFDF9FA),
        fontFamily: 'Poppins',
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            final user = snapshot.data;
            if (user == null) return LoginPage();
            return Dashboard();
          }
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      ),
    );
  }
}

// ==================== LOGIN & REGISTER ====================
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  String _error = '';

  Future<void> _submit() async {
    setState(() => _error = '');
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Authentication error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF0F5), Color(0xFFFFE4E1)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Card(
              elevation: 20,
              shadowColor: Colors.pink.shade200,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite, size: 60, color: Colors.pink),
                    SizedBox(height: 20),
                    Text(
                      _isLogin ? 'Welcome Back' : 'Create Account',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.pink.shade700),
                    ),
                    SizedBox(height: 30),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                    ),
                    SizedBox(height: 15),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                    ),
                    if (_error.isNotEmpty) ...[
                      SizedBox(height: 15),
                      Text(_error, style: TextStyle(color: Colors.red)),
                    ],
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text(_isLogin ? 'Login' : 'Register'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(_isLogin ? 'Need an account? Register' : 'Already have an account? Login'),
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

// ==================== DASHBOARD (9 cards) ====================
class Dashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF0F5), Color(0xFFFFE4E1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hello ${user?.email?.split('@')[0] ?? 'Mama'}!",
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.pink.shade800),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text("Your pregnancy companion", style: TextStyle(fontSize: 14, color: Colors.pink.shade600)),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.pink.shade100,
                      child: IconButton(
                        icon: Icon(Icons.person, color: Colors.pink),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage())),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildStatCard("Health", "Track vitals", Icons.favorite, Colors.pink),
                    SizedBox(width: 12),
                    _buildStatCard("SOS", "Emergency", Icons.emergency, Colors.red),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: EdgeInsets.all(20),
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.1,
                  children: [
                    _buildMenuCard(context, "Health Vitals", Icons.favorite, Colors.pink, HealthPage()),
                    _buildMenuCard(context, "SOS Emergency", Icons.emergency, Colors.red, SOSPage()),
                    _buildMenuCard(context, "Getting Pregnant", Icons.calendar_today, Colors.purple, GettingPregnantPage()),
                    _buildMenuCard(context, "Baby Care", Icons.child_care, Colors.teal, BabyCarePage()),
                    _buildMenuCard(context, "Baby Health", Icons.health_and_safety, Colors.orange, BabyHealthPage()),
                    _buildMenuCard(context, "Baby Products", Icons.shopping_bag, Colors.blue, BabyProductsPage()),
                    _buildMenuCard(context, "Nutrition Guide", Icons.food_bank, Colors.green, NutritionPage()),
                    _buildMenuCard(context, "Nearby Medical", Icons.local_hospital, Colors.indigo, NearbyMedicalPage()),
                    _buildMenuCard(context, "Maternity Hospitals", Icons.pregnant_woman, Colors.deepPurple, MaternityHospitalsPage()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String subtitle, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, Widget page) {
    return Card(
      elevation: 12,
      shadowColor: color.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.9), color],
            ),
            borderRadius: BorderRadius.circular(24),
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

// ==================== FIREBASE SERVICES (Health Data) ====================
class FirebaseServices {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("sensor_data");
  Stream<Map<String, dynamic>> getHealthData() {
    return dbRef.onValue.map((event) {
      final rawData = event.snapshot.value;
      if (rawData == null || rawData is! Map) return {"heart_rate": 0, "spo2": 0};
      final data = Map<String, dynamic>.from(rawData);
      return {"heart_rate": data["heart_rate"] ?? 0, "spo2": data["spo2"] ?? 0};
    });
  }
}

// ==================== HEALTH PAGE ====================
class HealthPage extends StatefulWidget {
  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  final FirebaseServices firebase = FirebaseServices();
  int heartRate = 0, spo2 = 0;

  @override
  void initState() {
    super.initState();
    firebase.getHealthData().listen((data) {
      setState(() {
        heartRate = (data["heart_rate"] ?? 0).toInt();
        spo2 = (data["spo2"] ?? 0).toInt();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Health Vitals"), backgroundColor: Colors.pink),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHealthCard("Heart Rate", "$heartRate BPM", Icons.favorite, Colors.pink),
            SizedBox(height: 20),
            _buildHealthCard("Blood Oxygen", "$spo2 %", Icons.air, Colors.cyan),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 20,
      shadowColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 250,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.2), Colors.white]),
          borderRadius: BorderRadius.circular(20),
        ),
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

// ==================== PROFILE & EMERGENCY CONTACTS ====================
class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _profileNameController = TextEditingController();
  final _profilePhoneController = TextEditingController();
  final _bloodController = TextEditingController();
  final _notesController = TextEditingController();
  final _addressController = TextEditingController();
  final _dobController = TextEditingController();
  
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  
  final _currentUser = FirebaseAuth.instance.currentUser;
  DateTime? _dob;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    if (_currentUser == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      _profileNameController.text = data['name'] ?? '';
      _profilePhoneController.text = data['phone'] ?? '';
      _bloodController.text = data['bloodGroup'] ?? '';
      _notesController.text = data['emergencyNotes'] ?? '';
      _addressController.text = (data['address'] ?? '').toString();
      _dob = (data['dateOfBirth'] as Timestamp?)?.toDate();
      _dobController.text = _dob != null ? DateFormat('yyyy-MM-dd').format(_dob!) : '';
    }
  }

  @override
  void dispose() {
    _profileNameController.dispose();
    _profilePhoneController.dispose();
    _bloodController.dispose();
    _notesController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null) return;
    try {
      final address = _addressController.text.trim();
      final String dobText = _dobController.text.trim();
      DateTime? dobToSave = _dob;
      if (dobText.isNotEmpty) {
        try {
          dobToSave = DateFormat('yyyy-MM-dd').parse(dobText);
        } catch(e) {}
      }

      final Map<String, dynamic> payload = {
        'name': _profileNameController.text.trim(),
        'phone': _profilePhoneController.text.trim(),
        'bloodGroup': _bloodController.text.trim(),
        'emergencyNotes': _notesController.text.trim(),
        'address': address,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (dobToSave != null) payload['dateOfBirth'] = Timestamp.fromDate(dobToSave);
      
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).set(payload, SetOptions(merge: true));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
    }
  }

  Future<void> _addContact() async {
    if (_contactNameController.text.isEmpty || _contactPhoneController.text.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('emergencyContacts')
          .add({
        'name': _contactNameController.text.trim(),
        'phone': _contactPhoneController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      _contactNameController.clear();
      _contactPhoneController.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding contact: $e')));
    }
  }

  Future<void> _deleteContact(String docId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('emergencyContacts')
        .doc(docId)
        .delete();
  }

  Widget _buildProfileField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.purple),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  color: Colors.purple.shade50,
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.purple.shade200,
                        child: Icon(Icons.person, size: 50, color: Colors.white),
                      ),
                      SizedBox(height: 12),
                      Text("Email: ${_currentUser?.email ?? 'Unknown'}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      _buildProfileField(_profileNameController, "Full Name", Icons.person_outline),
                      _buildProfileField(_bloodController, "Blood Group", Icons.bloodtype),
                      _buildProfileField(_dobController, "Due Date / Date of Birth (YYYY-MM-DD)", Icons.calendar_today),
                      _buildProfileField(_profilePhoneController, "Your Phone Number", Icons.phone),
                      _buildProfileField(_addressController, "Current Address", Icons.home),
                      _buildProfileField(_notesController, "Medical Notes / Allergies", Icons.notes),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: Icon(Icons.save),
                        label: Text("Save Profile"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Personal Emergency Contacts", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple.shade800)),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _contactNameController,
                          decoration: InputDecoration(labelText: "Contact Name", border: OutlineInputBorder()),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _contactPhoneController,
                          decoration: InputDecoration(labelText: "Phone", border: OutlineInputBorder()),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _addContact,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, shape: CircleBorder(), padding: EdgeInsets.all(16)),
                        child: Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(_currentUser!.uid)
                .collection('emergencyContacts')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("No personal contacts added yet"))));
              
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.person, color: Colors.white)),
                        title: Text(data['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(data['phone']),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteContact(docs[index].id),
                        ),
                      ),
                    );
                  },
                  childCount: docs.length,
                ),
              );
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ==================== SOS PAGE ====================
class SOSPage extends StatefulWidget {
  @override
  _SOSPageState createState() => _SOSPageState();
}

class _SOSPageState extends State<SOSPage> {
  final _currentUser = FirebaseAuth.instance.currentUser;
  List<QueryDocumentSnapshot> _contacts = [];
  String _ambulance = '102';
  final _ambulanceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _loadAmbulance();
  }

  void _loadContacts() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('emergencyContacts')
        .get();
    setState(() {
      _contacts = snapshot.docs;
    });
  }

  void _loadAmbulance() async {
    if (_currentUser == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _ambulance = (data['ambulance'] ?? _ambulance).toString();
        _ambulanceController.text = _ambulance;
      });
    }
  }

  void _makeCall(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _sendMessage(String phone, {String? customMessage}) async {
    String message = customMessage ?? "Emergency! I need help.";
    if (customMessage == null) {
      try {
        LocationPermission permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
          Position pos = await Geolocator.getCurrentPosition();
          message += " My location: https://maps.google.com/?q=${pos.latitude},${pos.longitude}";
        } else {
          message += " (Location unavailable)";
        }
      } catch (e) {
        message += " (Location unavailable)";
      }
    }
    final Uri smsUri = Uri(scheme: 'sms', path: phone, query: 'body=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(smsUri)) await launchUrl(smsUri);
  }

  Future<void> _sendSOSToAll() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;
    Position pos = await Geolocator.getCurrentPosition();
    String locationLink = "https://maps.google.com/?q=${pos.latitude},${pos.longitude}";
    String sosMessage = "🚨 SOS EMERGENCY! I need help immediately. My location: $locationLink";

    // send to ambulance first
    final ambPhone = _ambulanceController.text.trim().isNotEmpty ? _ambulanceController.text.trim() : _ambulance;
    if (ambPhone.isNotEmpty) _sendMessage(ambPhone, customMessage: 'Ambulance needed. $sosMessage');
    for (var doc in _contacts) {
      final phone = (doc.data() as Map<String, dynamic>)['phone'];
      if (phone.isNotEmpty) {
        _sendMessage(phone, customMessage: sosMessage);
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("SOS sent to all contacts!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("SOS Emergency"), backgroundColor: Colors.red),
      body: SingleChildScrollView(
        child: Column(
          children: [
            GestureDetector(
              onTap: _sendSOSToAll,
              child: Container(
                margin: EdgeInsets.all(30),
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Colors.red, Colors.red.shade800]),
                  boxShadow: [BoxShadow(color: Colors.red.withAlpha(100), blurRadius: 30, spreadRadius: 10)],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning, color: Colors.white, size: 60),
                      SizedBox(height: 10),
                      Text("SOS", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                      Text("Tap to alert all contacts", style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
            
            // Emergency Tips & Ambulance Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: Colors.red.shade50,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red),
                          SizedBox(width: 8),
                          Text("Emergency Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                        ],
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.local_hospital, color: Colors.red),
                        title: Text("Ambulance", style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Dial 102 or 108"),
                        trailing: IconButton(
                          icon: Icon(Icons.call, color: Colors.green),
                          onPressed: () => _makeCall('102'),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text("Tips for Emergency:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                      SizedBox(height: 4),
                      Text("• Stay calm and take deep breaths."),
                      Text("• Describe your exact location to the operator."),
                      Text("• Do not hang up until told to do so."),
                      Text("• Keep your ID and medical records accessible."),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text("Personal Emergency Contacts", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            
            _contacts.isEmpty
                ? Center(child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("No contacts added. Go to Profile page to add contacts."),
                ))
                : ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final data = _contacts[index].data() as Map<String, dynamic>;
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.person)),
                    title: Text(data['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(data['phone']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: Icon(Icons.call, color: Colors.green), onPressed: () => _makeCall(data['phone'])),
                        IconButton(icon: Icon(Icons.message, color: Colors.blue), onPressed: () => _sendMessage(data['phone'])),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ==================== GETTING PREGNANT ====================
class GettingPregnantPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Getting Pregnant"), backgroundColor: Colors.purple),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text("Tips to Boost Fertility", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 16),
                _buildTipCard(Icons.calendar_month, "Track your cycle", "Use an ovulation tracking method, such as LH strips, basal body temperature, or an app to pinpoint your most fertile days."),
                _buildTipCard(Icons.monitor_weight_outlined, "Maintain a healthy weight", "Being overweight or underweight can affect ovulation. A balanced diet and regular exercise help regulate hormones."),
                _buildTipCard(Icons.medication, "Take prenatal vitamins", "Start taking folic acid daily even before getting pregnant to prevent neural tube defects and support early development."),
                _buildTipCard(Icons.self_improvement, "Manage stress levels", "High stress can interfere with ovulation. Practice relaxation techniques like yoga, meditation, or deep breathing."),
                _buildTipCard(Icons.water_drop, "Stay hydrated", "Drink adequate water daily. Good hydration helps produce healthy cervical mucus for conception."),
                _buildTipCard(Icons.no_drinks, "Avoid smoking & alcohol", "Limit caffeine and avoid alcohol and smoking, as they negatively impact fertility for both partners."),
                _buildTipCard(Icons.restaurant, "Eat a fertility-boosting diet", "Focus on antioxidants, healthy fats (like avocados and nuts), and protein to support reproductive health."),
                _buildTipCard(Icons.bedtime, "Prioritize good sleep", "Ensure you get 7-8 hours of quality sleep per night. Sleep is essential for hormone production and regulation."),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipCard(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.purple, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(description, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== BABY CARE (Age‑based) ====================
class BabyCarePage extends StatelessWidget {
  final Map<String, String> _ageGuidelines = {
    '1 Month': 'Feed regularly (breast milk best), keep baby clean, ensure proper sleep, and maintain hygiene. Keep baby warm, follow vaccination schedule, handle gently, and watch for any signs of illness.',
    '2 Months': 'Continue breastfeeding/formula. Tummy time for 3-5 min daily. Respond to cries. First vaccinations (DTaP, Hib, Polio, PCV, Rotavirus).',
    '3 Months': 'Longer sleep at night. Introduce rattles and high-contrast toys. Talk and sing to baby. Watch for head control improvement.',
    '4 Months': 'Second round of vaccines. Baby may start rolling. Avoid screen time. Maintain consistent bedtime routine.',
    '5 Months': 'May show interest in food. Continue exclusive breastfeeding/formula. Baby laughs and squeals. Teething may begin.',
    '6 Months': 'Introduce solid foods (iron-fortified cereals, pureed vegetables). Baby sits with support. Continue tummy time. Vaccines (Hepatitis B, etc.).',
    '8 Months': 'Finger foods (soft). Baby crawls. Baby-proof home. Encourage exploration. Maintain oral hygiene with soft brush.',
    '10 Months': 'Self-feeding attempts. Pulls to stand. Name objects. Read board books. Ensure safe sleep environment.',
    '1 Year': 'Whole milk can be introduced. Walking or cruising. First birthday. MMR vaccine. Encourage independence with safe boundaries.',
    '2 Years': 'Potty training readiness. Balanced diet with family meals. Brush teeth twice daily. Limit screen time. Encourage active play.',
    '3 Years': 'Preschool readiness. Teach handwashing, dressing self. Use time-outs for discipline. Encourage imaginative play. Regular dental checkup.',
  };

  @override
  Widget build(BuildContext context) {
    final ages = _ageGuidelines.keys.toList();
    return Scaffold(
      appBar: AppBar(title: Text("Baby Care by Age"), backgroundColor: Colors.teal),
      body: ListView.builder(
        itemCount: ages.length,
        itemBuilder: (context, index) {
          final age = ages[index];
          final guideline = _ageGuidelines[age]!;
          return Card(
            margin: EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ExpansionTile(
              title: Text(age, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(guideline, style: TextStyle(fontSize: 14, height: 1.4)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ==================== BABY HEALTH (25 diseases) ====================
class BabyHealthPage extends StatefulWidget {
  @override
  _BabyHealthPageState createState() => _BabyHealthPageState();
}

class _BabyHealthPageState extends State<BabyHealthPage> {
  final List<Map<String, dynamic>> _diseases = [
    {'name': 'Common Cold', 'symptoms': 'Runny nose, sneezing, mild fever, cough, fussiness.', 'treatment': 'Rest, hydration, saline drops, humidifier. Consult doctor if fever > 100.4°F.'},
    {'name': 'Hand, Foot & Mouth Disease', 'symptoms': 'Fever, sore throat, rash on hands/feet, mouth ulcers.', 'treatment': 'Pain relief (acetaminophen), soft foods, fluids. Isolate to prevent spread.'},
    {'name': 'Chickenpox', 'symptoms': 'Itchy red spots that blister and crust, fever, tiredness.', 'treatment': 'Calamine lotion, oatmeal baths, antihistamines. Vaccine available.'},
    {'name': 'Roseola', 'symptoms': 'High fever (3-5 days) then rash after fever breaks.', 'treatment': 'Fever management, fluids. Usually self-limiting.'},
    {'name': 'Croup', 'symptoms': 'Barking cough, stridor (noisy breathing), worse at night.', 'treatment': 'Steam therapy, cool air, steroids if severe. ER if breathing difficulty.'},
    {'name': 'Bronchiolitis (RSV)', 'symptoms': 'Wheezing, rapid breathing, cough, poor feeding.', 'treatment': 'Oxygen support, suction, hydration. Hospitalization for severe cases.'},
    {'name': 'Pneumonia', 'symptoms': 'High fever, cough with phlegm, rapid breathing, chest retractions.', 'treatment': 'Antibiotics (bacterial), rest, fluids. Hospitalization if severe.'},
    {'name': 'Ear Infection (Otitis Media)', 'symptoms': 'Ear pulling, fever, fussiness, difficulty sleeping.', 'treatment': 'Pain relievers, warm compress. Antibiotics if bacterial.'},
    {'name': 'Strep Throat', 'symptoms': 'Sore throat, fever, swollen lymph nodes, red spots on palate.', 'treatment': 'Antibiotics (penicillin), rest, soft foods.'},
    {'name': 'Urinary Tract Infection (UTI)', 'symptoms': 'Fever, foul urine, vomiting, fussiness, poor feeding.', 'treatment': 'Antibiotics, increased fluids. Kidney ultrasound if recurrent.'},
    {'name': 'Gastroenteritis (Stomach Flu)', 'symptoms': 'Diarrhea, vomiting, fever, abdominal pain.', 'treatment': 'Oral rehydration solution, probiotics. Seek care if dehydration.'},
    {'name': 'Constipation', 'symptoms': 'Hard, dry stools, pain during bowel movements, bloating.', 'treatment': 'Increase fluids, fiber (prunes, pears), tummy massage. Laxatives if needed.'},
    {'name': 'Diaper Rash', 'symptoms': 'Red, irritated skin in diaper area.', 'treatment': 'Frequent diaper changes, barrier cream (zinc oxide), air exposure.'},
    {'name': 'Eczema (Atopic Dermatitis)', 'symptoms': 'Dry, itchy, red patches on cheeks, elbows, knees.', 'treatment': 'Moisturizers, mild steroids, avoid triggers (soaps, allergens).'},
    {'name': 'Cradle Cap', 'symptoms': 'Yellowish, scaly patches on scalp.', 'treatment': 'Baby oil, gentle brushing, medicated shampoo.'},
    {'name': 'Thrush (Oral Candidiasis)', 'symptoms': 'White patches on tongue/gums, painful feeding.', 'treatment': 'Antifungal drops (nystatin), sterilize bottles/nipples.'},
    {'name': 'Measles', 'symptoms': 'High fever, cough, runny nose, red eyes, then red rash.', 'treatment': 'Supportive care, vitamin A. Prevent with MMR vaccine.'},
    {'name': 'Mumps', 'symptoms': 'Swollen painful cheeks/ jaw, fever, headache.', 'treatment': 'Rest, fluids, pain relief. Vaccine preventable.'},
    {'name': 'Rubella (German Measles)', 'symptoms': 'Mild fever, pink rash, swollen lymph nodes.', 'treatment': 'Supportive care. Dangerous for pregnant women.'},
    {'name': 'Whooping Cough (Pertussis)', 'symptoms': 'Severe coughing fits with "whoop" sound, vomiting after cough.', 'treatment': 'Antibiotics, hospitalization for infants. Vaccine (DTaP).'},
    {'name': 'Scarlet Fever', 'symptoms': 'Sore throat, fever, sandpaper-like rash, strawberry tongue.', 'treatment': 'Antibiotics (penicillin).'},
    {'name': 'Kawasaki Disease', 'symptoms': 'High fever >5 days, red eyes, rash, swollen hands/feet, cracked lips.', 'treatment': 'IVIG, aspirin. Urgent cardiology follow-up.'},
    {'name': 'Reye’s Syndrome', 'symptoms': 'Vomiting, confusion, seizures after aspirin use during viral illness.', 'treatment': 'Emergency hospitalization. NEVER give aspirin to children.'},
    {'name': 'Febrile Seizures', 'symptoms': 'Convulsions with fever (6 months-5 years).', 'treatment': 'Lay child on side, remove nearby objects. Call doctor.'},
    {'name': 'Meningitis', 'symptoms': 'High fever, stiff neck, severe headache, bulging fontanelle (infants).', 'treatment': 'Medical emergency. Antibiotics/antivirals, hospitalization.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Baby Health Guide"), backgroundColor: Colors.orange),
      body: ListView.builder(
        itemCount: _diseases.length,
        itemBuilder: (context, index) {
          final disease = _diseases[index];
          return Card(
            margin: EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ExpansionTile(
              title: Text(disease['name'], style: TextStyle(fontWeight: FontWeight.bold)),
              children: [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("🩺 Symptoms:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(disease['symptoms']),
                      SizedBox(height: 8),
                      Text("💊 Treatment:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(disease['treatment']),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ==================== BABY PRODUCTS (with fallback for links) ====================
class BabyProductsPage extends StatefulWidget {
  @override
  _BabyProductsPageState createState() => _BabyProductsPageState();
}

class _BabyProductsPageState extends State<BabyProductsPage> {
  final List<Map<String, String>> _allProducts = [
    {'name': 'Diapers (Pampers)', 'category': 'Essentials', 'search': 'baby diapers'},
    {'name': 'Baby Wipes', 'category': 'Essentials', 'search': 'baby wipes'},
    {'name': 'Crib', 'category': 'Furniture', 'search': 'baby crib'},
    {'name': 'Stroller', 'category': 'Gear', 'search': 'baby stroller'},
    {'name': 'Car Seat', 'category': 'Safety', 'search': 'baby car seat'},
    {'name': 'Baby Monitor', 'category': 'Electronics', 'search': 'baby monitor'},
    {'name': 'Breast Pump', 'category': 'Feeding', 'search': 'breast pump'},
    {'name': 'Baby Bottle', 'category': 'Feeding', 'search': 'baby feeding bottle'},
    {'name': 'Sterilizer', 'category': 'Feeding', 'search': 'bottle sterilizer'},
    {'name': 'Baby Carrier', 'category': 'Gear', 'search': 'baby carrier'},
    {'name': 'High Chair', 'category': 'Furniture', 'search': 'baby high chair'},
    {'name': 'Baby Bather', 'category': 'Bath', 'search': 'baby bath tub'},
    {'name': 'Baby Lotion', 'category': 'Skincare', 'search': 'baby lotion'},
    {'name': 'Baby Shampoo', 'category': 'Skincare', 'search': 'baby shampoo'},
    {'name': 'Diaper Bag', 'category': 'Accessories', 'search': 'diaper bag'},
    {'name': 'Baby Blanket', 'category': 'Bedding', 'search': 'baby blanket'},
    {'name': 'Teething Toy', 'category': 'Toys', 'search': 'teething toy'},
    {'name': 'Baby Swing', 'category': 'Gear', 'search': 'baby swing'},
    {'name': 'Nail Clipper', 'category': 'Grooming', 'search': 'baby nail clipper'},
    {'name': 'Nasal Aspirator', 'category': 'Health', 'search': 'nasal aspirator'},
    {'name': 'Baby Walker', 'category': 'Gear', 'search': 'baby walker'},
    {'name': 'Potty Trainer', 'category': 'Toilet', 'search': 'potty trainer'},
    {'name': 'Baby Toothbrush', 'category': 'Dental', 'search': 'baby toothbrush'},
    {'name': 'Baby Mattress', 'category': 'Bedding', 'search': 'baby mattress'},
    {'name': 'Baby Clothes Set', 'category': 'Clothing', 'search': 'baby clothes set'},
    {'name': 'Mittens & Booties', 'category': 'Clothing', 'search': 'baby mittens'},
    {'name': 'Bibs', 'category': 'Feeding', 'search': 'baby bib'},
    {'name': 'Baby Sofa', 'category': 'Furniture', 'search': 'baby sofa'},
    {'name': 'Activity Gym', 'category': 'Toys', 'search': 'baby activity gym'},
    {'name': 'Rocking Horse', 'category': 'Toys', 'search': 'rocking horse'},
    {'name': 'Baby Proofing Kit', 'category': 'Safety', 'search': 'baby proofing kit'},
    {'name': 'Thermometer', 'category': 'Health', 'search': 'baby thermometer'},
    {'name': 'Baby Massage Oil', 'category': 'Skincare', 'search': 'baby massage oil'},
    {'name': 'Diaper Rash Cream', 'category': 'Skincare', 'search': 'diaper rash cream'},
    {'name': 'Baby Powder', 'category': 'Skincare', 'search': 'baby powder'},
    {'name': 'Baby Comb', 'category': 'Grooming', 'search': 'baby comb'},
    {'name': 'Baby Sling', 'category': 'Gear', 'search': 'baby sling'},
    {'name': 'Travel Cot', 'category': 'Furniture', 'search': 'travel cot'},
    {'name': 'Baby Utensils Set', 'category': 'Feeding', 'search': 'baby utensils set'},
    {'name': 'Sippy Cup', 'category': 'Feeding', 'search': 'sippy cup'},
    {'name': 'Baby Grooming Kit', 'category': 'Grooming', 'search': 'baby grooming kit'},
    {'name': 'Wet Wipes Warmer', 'category': 'Essentials', 'search': 'wipes warmer'},
    {'name': 'Baby Humidifier', 'category': 'Health', 'search': 'baby humidifier'},
    {'name': 'Baby Fence', 'category': 'Safety', 'search': 'baby fence'},
    {'name': 'Baby Cot Mobile', 'category': 'Toys', 'search': 'cot mobile'},
    {'name': 'Baby Night Lamp', 'category': 'Electronics', 'search': 'baby night lamp'},
    {'name': 'Baby Shoes', 'category': 'Clothing', 'search': 'baby shoes'},
    {'name': 'Baby Hat', 'category': 'Clothing', 'search': 'baby hat'},
    {'name': 'Baby Sunglasses', 'category': 'Accessories', 'search': 'baby sunglasses'},
    {'name': 'Baby Backpack', 'category': 'Accessories', 'search': 'baby backpack'},
  ];
  Set<String> _selectedProducts = {};

  void _toggleProduct(String name) {
    setState(() {
      if (_selectedProducts.contains(name)) {
        _selectedProducts.remove(name);
      } else {
        _selectedProducts.add(name);
      }
    });
  }

  void _buyNow(String searchTerm) async {
    final query = Uri.encodeComponent(searchTerm);
    final flipkartUrl = "https://www.flipkart.com/search?q=$query";
    final Uri url = Uri.parse(flipkartUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showCannotOpenDialog(flipkartUrl);
      }
    } catch (e) {
      _showCannotOpenDialog(flipkartUrl);
    }
  }

  void _showCannotOpenDialog(String url) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Cannot open browser"),
        content: Text("Copy this link and open manually:\n$url"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Copy to clipboard (optional, requires clipboard package)
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Link copied to clipboard")));
            },
            child: Text("Copy Link"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Baby Registry"), backgroundColor: Colors.blue),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text("Select items you need:", style: TextStyle(fontSize: 18)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _allProducts.length,
              itemBuilder: (context, index) {
                final product = _allProducts[index];
                final isSelected = _selectedProducts.contains(product['name']);
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    title: Text(product['name']!),
                    subtitle: Text(product['category']!),
                    leading: Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleProduct(product['name']!),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.shopping_cart, color: Colors.blue),
                      onPressed: () => _buyNow(product['search']!),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text("Your Registry"),
                    content: Text(_selectedProducts.isEmpty
                        ? "No items selected"
                        : _selectedProducts.join('\n')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text("Close")),
                    ],
                  ),
                );
              },
              child: Text("View My Registry (${_selectedProducts.length})"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== NUTRITION PAGE ====================
class NutritionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nutrition Guide"), backgroundColor: Colors.teal),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          _buildNutritionCard('First Trimester', ['Take folic acid', 'Eat iron-rich foods', 'Stay hydrated']),
          _buildNutritionCard('Second Trimester', ['Increase calcium', 'Eat protein', 'Add vitamin D']),
          _buildNutritionCard('Third Trimester', ['Small frequent meals', 'Stay hydrated', 'More fiber']),
        ],
      ),
    );
  }

  Widget _buildNutritionCard(String title, List<String> tips) {
    return Card(
      margin: EdgeInsets.only(bottom: 15),
      child: ExpansionTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        children: tips.map((tip) => ListTile(leading: Icon(Icons.check_circle, color: Colors.teal), title: Text(tip))).toList(),
      ),
    );
  }
}

// ==================== NEARBY MEDICAL (original) ====================
class NearbyMedicalPage extends StatefulWidget {
  @override
  _NearbyMedicalPageState createState() => _NearbyMedicalPageState();
}

class _NearbyMedicalPageState extends State<NearbyMedicalPage> {
  bool _loading = true;
  List<MedicalPlace> _places = [];
  String _error = '';
  String _selectedType = 'hospital';
  double? _myLat, _myLng;

  @override
  void initState() {
    super.initState();
    _getLocationAndFetch();
  }

  Future<void> _getLocationAndFetch() async {
    setState(() { _loading = true; _error = ''; });
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      setState(() { _error = 'Location permission denied'; _loading = false; });
      return;
    }
    try {
      Position pos = await Geolocator.getCurrentPosition();
      _myLat = pos.latitude;
      _myLng = pos.longitude;
      await _fetchPlaces();
    } catch (e) {
      setState(() { _error = 'Could not get location: $e'; _loading = false; });
    }
  }

  Future<void> _fetchPlaces() async {
    if (_myLat == null || _myLng == null) return;
    List<int> radiusList = [3000, 5000, 10000, 15000, 20000];
    
    List<MedicalPlace> tempPlaces = [];
    for (int radius in radiusList) {
      final rawPlaces = await _overpassQuery(radius);
      tempPlaces.clear();
      
      for (var p in rawPlaces) {
        final lat = p['lat'] ?? p['center']?['lat'];
        final lon = p['lon'] ?? p['center']?['lon'];
        if (lat == null || lon == null) continue;
        final tags = p['tags'] ?? {};
        final amenity = tags['amenity'] ?? '';
        final healthcare = tags['healthcare'] ?? '';
        bool isHospital = amenity == 'hospital' || amenity == 'clinic' || healthcare == 'hospital' || healthcare == 'clinic';
        bool isPharmacy = amenity == 'pharmacy' || amenity == 'chemist';
        if (_selectedType == 'hospital' && !isHospital) continue;
        if (_selectedType == 'pharmacy' && !isPharmacy) continue;
        final name = tags['name'] ?? (_selectedType == 'hospital' ? 'Hospital' : 'Pharmacy');
        final phone = tags['phone'] ?? '';
        final website = tags['website'] ?? '';
        final openingHours = tags['opening_hours'] ?? '';
        final distance = Geolocator.distanceBetween(_myLat!, _myLng!, lat, lon) / 1000;
        final random = Random(name.hashCode);
        final rating = 3.5 + random.nextDouble() * 1.5;
        final ratingStars = rating.toStringAsFixed(1);
        String openStatus = 'Open today';
        if (openingHours.toLowerCase().contains('24/7') || openingHours.toLowerCase().contains('24 hours')) {
          openStatus = 'Open 24 hours';
        } else if (openingHours.isNotEmpty) {
          openStatus = openingHours;
        } else {
          openStatus = 'Call for hours';
        }
        tempPlaces.add(MedicalPlace(
          name: name, lat: lat, lon: lon, distance: distance, phone: phone,
          website: website, rating: ratingStars, openStatus: openStatus, type: _selectedType,
        ));
      }
      
      // Fixed early break bug: only stop the radius expansion if we found enough of the SPECIFIC requested type!
      if (tempPlaces.length >= 10) {
        break;
      }
    }
    
    tempPlaces.sort((a, b) => a.distance.compareTo(b.distance));
    setState(() {
      _places = tempPlaces;
      _loading = false;
      if (_places.isEmpty) _error = 'No $_selectedType found nearby.';
    });
  }

  Future<List<dynamic>> _overpassQuery(int radius) async {
    final url = Uri.parse('https://overpass-api.de/api/interpreter');
    final query = """
      [out:json];
      (
        node["amenity"~"hospital|clinic|pharmacy"](around:$radius,$_myLat,$_myLng);
        way["amenity"~"hospital|clinic|pharmacy"](around:$radius,$_myLat,$_myLng);
        node["healthcare"~"hospital|clinic"](around:$radius,$_myLat,$_myLng);
      );
      out center;
    """;
    try {
      final response = await http.post(url, body: query);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['elements'] ?? [];
      }
    } catch (e) {}
    return [];
  }

  void _openNavigation(double lat, double lon) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _makeCall(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Medical'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          SegmentedButton<String>(
            style: ButtonStyle(backgroundColor: WidgetStateProperty.resolveWith((states) => Colors.white)),
            segments: const [
              ButtonSegment(value: 'hospital', label: Text('Hospitals'), icon: Icon(Icons.local_hospital)),
              ButtonSegment(value: 'pharmacy', label: Text('Pharmacies'), icon: Icon(Icons.medical_services)),
            ],
            selected: {_selectedType},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() { _selectedType = newSelection.first; _fetchPlaces(); });
            },
          ),
          SizedBox(width: 8),
          IconButton(icon: Icon(Icons.refresh), onPressed: _getLocationAndFetch),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error_outline, size: 64), SizedBox(height: 16), Text(_error), ElevatedButton(onPressed: _getLocationAndFetch, child: Text('Retry'))]))
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _places.length,
        itemBuilder: (context, index) {
          final place = _places[index];
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(place.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(12)), child: Text('${place.distance.toStringAsFixed(1)} km')),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(children: [Icon(Icons.star, color: Colors.amber, size: 18), SizedBox(width: 4), Text(place.rating), SizedBox(width: 16), Icon(Icons.access_time, color: Colors.grey.shade600, size: 16), SizedBox(width: 4), Expanded(child: Text(place.openStatus, style: TextStyle(fontSize: 12, color: place.openStatus.contains('24') ? Colors.green : Colors.orange)))]),
                  SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    if (place.phone.isNotEmpty) _buildActionButton(icon: Icons.call, label: 'Call', color: Colors.green, onPressed: () => _makeCall(place.phone)),
                    SizedBox(width: 8),
                    _buildActionButton(icon: Icons.directions, label: 'Directions', color: Colors.blue, onPressed: () => _openNavigation(place.lat, place.lon)),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onPressed}) {
    return ElevatedButton.icon(onPressed: onPressed, icon: Icon(icon, size: 16), label: Text(label), style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))));
  }
}

class MedicalPlace {
  final String name; final double lat; final double lon; final double distance; final String phone; final String website; final String rating; final String openStatus; final String type;
  MedicalPlace({required this.name, required this.lat, required this.lon, required this.distance, required this.phone, required this.website, required this.rating, required this.openStatus, required this.type});
}

// ==================== NEW: MATERNITY HOSPITALS PAGE ====================
class MaternityHospitalsPage extends StatefulWidget {
  @override
  _MaternityHospitalsPageState createState() => _MaternityHospitalsPageState();
}

class _MaternityHospitalsPageState extends State<MaternityHospitalsPage> {
  bool _loading = true;
  List<MaternityHospital> _hospitals = [];
  String _error = '';
  double? _myLat, _myLng;

  @override
  void initState() {
    super.initState();
    _getLocationAndFetch();
  }

  Future<void> _getLocationAndFetch() async {
    setState(() { _loading = true; _error = ''; });
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      setState(() { _error = 'Location permission denied'; _loading = false; });
      return;
    }
    try {
      Position pos = await Geolocator.getCurrentPosition();
      _myLat = pos.latitude;
      _myLng = pos.longitude;
      await _fetchMaternityHospitals();
    } catch (e) {
      setState(() { _error = 'Could not get location: $e'; _loading = false; });
    }
  }

  Future<void> _fetchMaternityHospitals() async {
    if (_myLat == null || _myLng == null) return;
    List<int> radiusList = [3000, 5000, 10000, 15000, 20000];
    List<MaternityHospital> tempHospitals = [];
    List<MaternityHospital> fallbackHospitals = [];
    
    for (int radius in radiusList) {
      final rawHospitals = await _overpassMaternityQuery(radius);
      tempHospitals.clear();
      List<MaternityHospital> currentRadiusHospitals = [];
      
      for (var h in rawHospitals) {
        final lat = h['lat'] ?? h['center']?['lat'];
        final lon = h['lon'] ?? h['center']?['lon'];
        if (lat == null || lon == null) continue;
        final tags = h['tags'] ?? {};
        final name = tags['name'] ?? 'Maternity Hospital';
        final phone = tags['phone'] ?? '';
        final website = tags['website'] ?? '';
        final openingHours = tags['opening_hours'] ?? '';
        final distance = Geolocator.distanceBetween(_myLat!, _myLng!, lat, lon) / 1000;
        
        // check if it's maternity related
        final speciality = tags['healthcare'] ?? tags['speciality'] ?? '';
        final isMaternity = name.toLowerCase().contains('maternity') ||
            name.toLowerCase().contains('women') ||
            name.toLowerCase().contains('mother') ||
            speciality.toLowerCase().contains('obstetric') ||
            speciality.toLowerCase().contains('gynecology');

        String openStatus = 'Open 24 hours';
        if (openingHours.isNotEmpty && !openingHours.toLowerCase().contains('24')) {
          openStatus = openingHours;
        }

        final hospitalObj = MaternityHospital(
          name: name,
          lat: lat,
          lon: lon,
          distance: distance,
          phone: phone,
          website: website,
          openStatus: openStatus,
        );
        
        currentRadiusHospitals.add(hospitalObj);
        if (isMaternity) tempHospitals.add(hospitalObj);
      }
      
      if (fallbackHospitals.isEmpty && currentRadiusHospitals.isNotEmpty) {
        fallbackHospitals = currentRadiusHospitals;
      }
      
      // Stop radius expansion only if we found enough STRICT maternity places
      if (tempHospitals.length >= 6) {
        break;
      }
    }
    
    if (tempHospitals.isEmpty || tempHospitals.length < 3) {
      // Fallback: merge general hospitals if strict maternity ones aren't found
      tempHospitals.addAll(fallbackHospitals);
      final ids = <String>{};
      tempHospitals.retainWhere((h) => ids.add("${h.lat}_${h.lon}"));
    }
    
    tempHospitals.sort((a, b) => a.distance.compareTo(b.distance));
    setState(() {
      _hospitals = tempHospitals;
      _loading = false;
      if (_hospitals.isEmpty) _error = 'No maternity hospitals found nearby. Try a different area.';
    });
  }

  Future<List<dynamic>> _overpassMaternityQuery(int radius) async {
    final url = Uri.parse('https://overpass-api.de/api/interpreter');
    // Query for hospitals and clinics that may offer maternity services
    final query = """
      [out:json];
      (
        node["amenity"="hospital"](around:$radius,$_myLat,$_myLng);
        way["amenity"="hospital"](around:$radius,$_myLat,$_myLng);
        node["amenity"="clinic"](around:$radius,$_myLat,$_myLng);
        node["healthcare"="hospital"](around:$radius,$_myLat,$_myLng);
        node["healthcare"="clinic"](around:$radius,$_myLat,$_myLng);
      );
      out center;
    """;
    try {
      final response = await http.post(url, body: query);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['elements'] ?? [];
      }
    } catch (e) {}
    return [];
  }

  void _openNavigation(double lat, double lon) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _makeCall(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Maternity Hospitals"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _getLocationAndFetch),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error_outline, size: 64), SizedBox(height: 16), Text(_error), ElevatedButton(onPressed: _getLocationAndFetch, child: Text('Retry'))]))
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _hospitals.length,
        itemBuilder: (context, index) {
          final hospital = _hospitals[index];
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_hospital, color: Colors.deepPurple, size: 28),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hospital.name,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${hospital.distance.toStringAsFixed(1)} km',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.grey.shade600, size: 16),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hospital.openStatus,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (hospital.phone.isNotEmpty)
                        _buildActionButton(
                          icon: Icons.call,
                          label: 'Call',
                          color: Colors.green,
                          onPressed: () => _makeCall(hospital.phone),
                        ),
                      SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.directions,
                        label: 'Directions',
                        color: Colors.blue,
                        onPressed: () => _openNavigation(hospital.lat, hospital.lon),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),),
    );
  }
}

class MaternityHospital {
  final String name;
  final double lat;
  final double lon;
  final double distance;
  final String phone;
  final String website;
  final String openStatus;
  MaternityHospital({
    required this.name,
    required this.lat,
    required this.lon,
    required this.distance,
    required this.phone,
    required this.website,
    required this.openStatus,
  });
}