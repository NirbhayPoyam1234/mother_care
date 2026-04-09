import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    print("Firebase connected successfully!");
  } catch (e) {
    print("Firebase not configured yet. App will work without it: $e");
  }
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pregnancy Health Support',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFDF9FA),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink, primary: Colors.pink),
        useMaterial3: true,
      ),
      home: const Root(),
    );
  }
}

// MAIN NAVIGATION
class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  int currentTab = 0;

  final List<Widget> screens = [
    const HomeScreen(),
    const HealthScreen(),
    const SOSScreen(),
    const MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentTab],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          child: BottomNavigationBar(
            currentIndex: currentTab,
            onTap: (index) {
              setState(() {
                currentTab = index;
              });
            },
            selectedItemColor: Colors.pink,
            unselectedItemColor: Colors.grey.shade400,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: 'Health'),
              BottomNavigationBarItem(icon: Icon(Icons.emergency_rounded), label: 'SOS'),
              BottomNavigationBarItem(icon: Icon(Icons.apps_rounded), label: 'More'),
            ],
          ),
        ),
      ),
    );
  }
}

// REUSABLE HEADER WIDGET
Widget customHeader(String title, String subtitle, {Color? bgColor, IconData? icon}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(25, 60, 25, 30),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: bgColor != null ? [bgColor, bgColor.withOpacity(0.8)] : [Colors.pink, Colors.pinkAccent],
      ),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(subtitle, style: const TextStyle(fontSize: 15, color: Colors.white70)),
            ],
          ),
        ),
        if (icon != null)
          Icon(icon, color: Colors.white.withOpacity(0.5), size: 60),
      ],
    ),
  );
}

// ==================== SCREEN 1: HOME SCREEN ====================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      {'icon': Icons.local_hospital, 'title': 'Hospitals', 'color': Colors.blue},
      {'icon': Icons.person, 'title': 'Find Doctors', 'color': Colors.green},
      {'icon': Icons.abc, 'title': 'Baby Names', 'color': Colors.orange},
      {'icon': Icons.food_bank, 'title': 'Nutrition', 'color': Colors.teal},
      {'icon': Icons.favorite, 'title': 'Health Tips', 'color': Colors.pink},
      {'icon': Icons.psychology, 'title': 'Wellness', 'color': Colors.purple},
    ];

    return Scaffold(
      body: Column(
        children: [
          customHeader("Hello Mama! 👋", "Your pregnancy companion", icon: Icons.child_care),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.2,
              ),
              itemCount: features.length,
              itemBuilder: (context, index) {
                final feature = features[index];
                return InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Explore ${feature['title']} in More tab!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: (feature['color'] as Color).withOpacity(0.1),
                          radius: 25,
                          child: Icon(feature['icon'] as IconData, color: feature['color'] as Color, size: 28),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          feature['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== SCREEN 2: HEALTH DASHBOARD ====================
class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  int heartRate = 0;
  int bloodOxygen = 0;
  bool isConnected = false;
  StreamSubscription? subscription;

  @override
  void initState() {
    super.initState();
    _connectToFirebase();
  }

  void _connectToFirebase() {
    try {
      // Try to connect to Firebase Realtime Database
      final databaseRef = FirebaseDatabase.instance.ref('sensor_data');
      subscription = databaseRef.onValue.listen((event) {
        print("👉 LIVE FIREBASE SNAPSHOT RECEIVED: ${event.snapshot.value}");
        setState(() {
          isConnected = true;
          if (event.snapshot.value != null && event.snapshot.value is Map) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            heartRate = (data['heart_rate'] ?? 0).toInt();
            bloodOxygen = (data['spo2'] ?? 0).toInt();
          }
        });
      }, onError: (error) {
        print("❌ FIREBASE STREAM ERROR (Check Rules): $error");
        setState(() { isConnected = false; });
      });
    } catch (e) {
      print("Firebase not connected. Waiting for live data.");
      setState(() {
        isConnected = false;
      });
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  Widget healthCard(String title, int value, String unit, IconData icon, Color color) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value == 0 ? "--" : "$value",
                      style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: color),
                    ),
                    const SizedBox(width: 5),
                    Text(unit, style: TextStyle(color: color.withOpacity(0.7))),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          customHeader(
            "Health Vitals",
            isConnected ? "Live data from MAX30100" : "Waiting for Sensor...",
            bgColor: Colors.indigo,
            icon: isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                healthCard("Heart Rate", heartRate, "BPM", Icons.favorite, Colors.pink),
                const SizedBox(height: 15),
                healthCard("Blood Oxygen", bloodOxygen, "% SpO₂", Icons.air, Colors.cyan),
                const SizedBox(height: 15),
                Card(
                  color: isConnected ? Colors.green.shade50 : Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        Icon(
                          isConnected ? Icons.check_circle : Icons.warning,
                          color: isConnected ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isConnected
                                ? "MAX30100 sensor connected. Reading real-time data."
                                : "Sensor not connected. Waiting for live data from Firebase.",
                            style: TextStyle(
                              fontSize: 12,
                              color: isConnected ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== SCREEN 3: SOS EMERGENCY ====================
class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  final List<Map<String, String>> contacts = [
    {'name': 'Dr. Sarah Johnson', 'phone': '+1234567890', 'relation': 'Doctor'},
    {'name': 'Emergency Services', 'phone': '911', 'relation': 'Emergency'},
    {'name': 'Husband', 'phone': '+1987654321', 'relation': 'Family'},
  ];

  Future<void> makeCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot make call to $phoneNumber')),
        );
      }
    } catch (e) {
      print("Error making call: $e");
    }
  }

  void sendSOSMessage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚨 SOS Activated 🚨'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Emergency alert sent to:'),
            const SizedBox(height: 10),
            ...contacts.map((contact) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('• ${contact['name']} (${contact['relation']})'),
            )),
            const SizedBox(height: 15),
            const Text('Your location and health data are being shared.', textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help is on the way! Emergency contacts notified.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm Emergency'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          customHeader(
            "Emergency SOS",
            "Tap for immediate help",
            bgColor: Colors.red,
            icon: Icons.warning_rounded,
          ),
          const SizedBox(height: 30),

          // Big SOS Button
          Center(
            child: InkWell(
              onTap: sendSOSMessage,
              borderRadius: BorderRadius.circular(100),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.call, color: Colors.white, size: 60),
                    SizedBox(height: 10),
                    Text(
                      "SOS",
                      style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Quick Contacts
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Quick Contacts",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: contact['relation'] == 'Doctor'
                          ? Colors.blue
                          : (contact['relation'] == 'Emergency' ? Colors.red : Colors.orange),
                      child: Icon(
                        contact['relation'] == 'Doctor'
                            ? Icons.medical_services
                            : (contact['relation'] == 'Emergency' ? Icons.warning : Icons.favorite),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(contact['name']!),
                    subtitle: Text(contact['phone']!),
                    trailing: IconButton(
                      icon: const Icon(Icons.phone, color: Colors.green),
                      onPressed: () => makeCall(contact['phone']!),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== SCREEN 4: MORE FEATURES ====================
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      {'title': 'Baby Names', 'icon': Icons.abc, 'color': Colors.pink, 'screen': const BabyNamesScreen()},
      {'title': 'Nutrition Guide', 'icon': Icons.food_bank, 'color': Colors.teal, 'screen': const NutritionScreen()},
      {'title': 'Find Doctors', 'icon': Icons.person_search, 'color': Colors.green, 'screen': const DoctorsScreen()},
      {'title': 'Nearby Hospitals', 'icon': Icons.local_hospital, 'color': Colors.blue, 'screen': const HospitalsScreen()},
      {'title': 'Kick Counter', 'icon': Icons.child_care, 'color': Colors.purple, 'screen': const KickCounterScreen()},
      {'title': 'Contraction Timer', 'icon': Icons.timer, 'color': Colors.orange, 'screen': const TimerScreen()},
    ];

    return Scaffold(
      body: Column(
        children: [
          customHeader(
            "All Features",
            "Tools to support your journey",
            bgColor: Colors.purple,
            icon: Icons.explore,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: features.length,
              itemBuilder: (context, index) {
                final feature = features[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (feature['color'] as Color).withOpacity(0.1),
                      child: Icon(feature['icon'] as IconData, color: feature['color'] as Color),
                    ),
                    title: Text(
                      feature['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => feature['screen'] as Widget),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== BABY NAMES SCREEN ====================
class BabyNamesScreen extends StatefulWidget {
  const BabyNamesScreen({super.key});

  @override
  State<BabyNamesScreen> createState() => _BabyNamesScreenState();
}

class _BabyNamesScreenState extends State<BabyNamesScreen> {
  final List<String> favoriteNames = [];
  final TextEditingController nameController = TextEditingController();

  final List<Map<String, String>> allNames = [
    {'name': 'Emma', 'meaning': 'Universal', 'gender': 'Girl'},
    {'name': 'Olivia', 'meaning': 'Olive tree', 'gender': 'Girl'},
    {'name': 'Sophia', 'meaning': 'Wisdom', 'gender': 'Girl'},
    {'name': 'Liam', 'meaning': 'Strong warrior', 'gender': 'Boy'},
    {'name': 'Noah', 'meaning': 'Rest', 'gender': 'Boy'},
    {'name': 'Oliver', 'meaning': 'Olive tree', 'gender': 'Boy'},
    {'name': 'Ava', 'meaning': 'Bird', 'gender': 'Girl'},
    {'name': 'Isabella', 'meaning': 'Devoted', 'gender': 'Girl'},
    {'name': 'Mia', 'meaning': 'Mine', 'gender': 'Girl'},
    {'name': 'Ethan', 'meaning': 'Strong', 'gender': 'Boy'},
  ];

  void addToFavorites(String name) {
    setState(() {
      if (!favoriteNames.contains(name)) {
        favoriteNames.add(name);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name added to favorites!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Baby Names'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Favorite Names (${favoriteNames.length})'),
                  content: favoriteNames.isEmpty
                      ? const Text('No favorite names yet.')
                      : Container(
                    height: 200,
                    width: double.maxFinite,
                    child: ListView.builder(
                      itemCount: favoriteNames.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(favoriteNames[index]),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                favoriteNames.removeAt(index);
                              });
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Name removed')),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'Add your own name...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      addToFavorites(nameController.text);
                      nameController.clear();
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: allNames.length,
              itemBuilder: (context, index) {
                final name = allNames[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: name['gender'] == 'Girl' ? Colors.pink.shade50 : Colors.blue.shade50,
                      child: Text(name['gender'] == 'Girl' ? '👧' : '👦', style: const TextStyle(fontSize: 20)),
                    ),
                    title: Text(name['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(name['meaning']!),
                    trailing: IconButton(
                      icon: Icon(
                        favoriteNames.contains(name['name']) ? Icons.favorite : Icons.favorite_border,
                        color: favoriteNames.contains(name['name']) ? Colors.pink : Colors.grey,
                      ),
                      onPressed: () => addToFavorites(name['name']!),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== NUTRITION SCREEN ====================
class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nutritionData = [
      {'title': 'First Trimester', 'tips': ['Take folic acid', 'Eat iron-rich foods', 'Stay hydrated', 'Avoid raw fish']},
      {'title': 'Second Trimester', 'tips': ['Increase calcium', 'Eat protein', 'Add vitamin D', 'Healthy fats']},
      {'title': 'Third Trimester', 'tips': ['Small frequent meals', 'Stay hydrated', 'More fiber', 'Iron supplements']},
      {'title': 'Foods to Avoid', 'tips': ['Raw meat', 'Raw eggs', 'Unpasteurized dairy', 'Alcohol', 'Excess caffeine']},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Guide'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: nutritionData.length,
        itemBuilder: (context, index) {
          final section = nutritionData[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 15),
            child: ExpansionTile(
              title: Text(
                section['title'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              children: (section['tips'] as List<String>).map((tip) {
                return ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.teal),
                  title: Text(tip),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

// ==================== DOCTORS SCREEN ====================
class DoctorsScreen extends StatelessWidget {
  const DoctorsScreen({super.key});

  final List<Map<String, String>> doctors = const [
    {'name': 'Dr. Sarah Johnson', 'specialty': 'Obstetrician', 'experience': '15 years', 'rating': '4.9'},
    {'name': 'Dr. Priya Sharma', 'specialty': 'Fetal Medicine', 'experience': '12 years', 'rating': '4.8'},
    {'name': 'Dr. Emily Brown', 'specialty': 'Pregnancy Specialist', 'experience': '10 years', 'rating': '4.7'},
    {'name': 'Dr. Maria Garcia', 'specialty': 'Gynecologist', 'experience': '14 years', 'rating': '4.9'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Doctors'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: doctors.length,
        itemBuilder: (context, index) {
          final doctor = doctors[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 15),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade50,
                child: const Icon(Icons.person, color: Colors.green),
              ),
              title: Text(doctor['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${doctor['specialty']} • ${doctor['experience']}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                      Text(' ${doctor['rating']}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Appointment requested!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(80, 30),
                    ),
                    child: const Text('Book', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================== HOSPITALS SCREEN ====================
class HospitalsScreen extends StatelessWidget {
  const HospitalsScreen({super.key});

  final List<Map<String, String>> hospitals = const [
    {'name': 'City General Hospital', 'address': '123 Main Street', 'distance': '1.2 km', 'phone': '+1234567890'},
    {'name': 'Women\'s Care Hospital', 'address': '456 Health Avenue', 'distance': '2.5 km', 'phone': '+1234567891'},
    {'name': 'Maternity Wellness Center', 'address': '789 Peace Road', 'distance': '3.0 km', 'phone': '+1234567892'},
  ];

  Future<void> callHospital(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Hospitals'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: hospitals.length,
        itemBuilder: (context, index) {
          final hospital = hospitals[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 15),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade50,
                child: const Icon(Icons.local_hospital, color: Colors.blue),
              ),
              title: Text(hospital['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${hospital['address']} • ${hospital['distance']}'),
              trailing: IconButton(
                icon: const Icon(Icons.call, color: Colors.green),
                onPressed: () => callHospital(hospital['phone']!),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================== KICK COUNTER SCREEN ====================
class KickCounterScreen extends StatefulWidget {
  const KickCounterScreen({super.key});

  @override
  State<KickCounterScreen> createState() => _KickCounterScreenState();
}

class _KickCounterScreenState extends State<KickCounterScreen> {
  int kickCount = 0;
  final List<String> kickTimes = [];

  void addKick() {
    setState(() {
      kickCount++;
      final now = DateTime.now();
      final timeString = '${now.hour}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      kickTimes.insert(0, timeString);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kick Counter'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          GestureDetector(
            onTap: addKick,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.purple.shade100, width: 8),
                boxShadow: [
                  BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 40),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.child_care, size: 60, color: Colors.purple),
                  const SizedBox(height: 10),
                  Text(
                    'Tap Here',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Total Kicks: $kickCount',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Recent Kicks:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: kickTimes.isEmpty
                ? const Center(child: Text('No kicks recorded yet.\nTap the circle above!', textAlign: TextAlign.center))
                : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: kickTimes.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.favorite, color: Colors.purple),
                    title: const Text('Kick detected'),
                    trailing: Text(kickTimes[index], style: const TextStyle(color: Colors.grey)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== CONTRACTION TIMER SCREEN ====================
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  bool isRunning = false;
  int seconds = 0;
  final List<String> history = [];
  Timer? timer;

  void startTimer() {
    setState(() {
      isRunning = true;
    });
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        seconds++;
      });
    });
  }

  void stopTimer() {
    timer?.cancel();
    setState(() {
      isRunning = false;
      if (seconds > 0) {
        final minutes = seconds ~/ 60;
        final remainingSeconds = seconds % 60;
        final timeString = '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
        history.insert(0, timeString);
      }
      seconds = 0;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contraction Timer'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 50),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 70, fontWeight: FontWeight.w200),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: isRunning ? stopTimer : startTimer,
            style: ElevatedButton.styleFrom(
              backgroundColor: isRunning ? Colors.red : Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(
              isRunning ? 'STOP' : 'START',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 30),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('History:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: history.isEmpty
                ? const Center(child: Text('No contractions recorded yet.\nPress START to begin tracking!', textAlign: TextAlign.center))
                : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: history.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.access_time, color: Colors.orange),
                    title: Text('Contraction #${history.length - index}'),
                    trailing: Text(history[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}