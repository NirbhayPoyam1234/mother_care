import 'package:flutter/material.dart';

// ...existing code...

class BabyCarePage extends StatelessWidget {
  final int maxAgeYears;
  // if original constructor different, adjust accordingly
  BabyCarePage({this.maxAgeYears = 4});

  // Example data structure; adapt to your real data source
  final List<Map<String, dynamic>> allEntries = [
    // ...existing code...
    // Example entry: {'title': 'Feeding tips', 'ageYears': 0.5, 'content': '...'}
  ];

  @override
  Widget build(BuildContext context) {
    // Filter entries to only those with ageYears <= maxAgeYears
    final filtered = allEntries.where((e) {
      final age = (e['ageYears'] is num) ? e['ageYears'] as num : 0;
      return age <= maxAgeYears;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Baby Care (up to $maxAgeYears yrs)')),
      body: ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: filtered.length,
        itemBuilder: (context, i) {
          final item = filtered[i];
          return Card(
            child: ListTile(
              title: Text(item['title'] ?? 'Untitled'),
              subtitle: Text(item['content'] ?? ''),
            ),
          );
        },
      ),
    );
  }
}

