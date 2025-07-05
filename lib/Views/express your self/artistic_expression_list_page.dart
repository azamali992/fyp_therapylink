// lib/Views/express_your_self/artistic_expression_list_page.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:therapylink/utils/colors.dart';
import 'artistic_expression_detail_page.dart';

class ArtisticExpressionListPage extends StatelessWidget {
  const ArtisticExpressionListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(color: Colors.white),
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            "Your Art",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          backgroundColor: AppColors.bgpurple,
        ),
        body: const Center(
          child: Text("Please log in.", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    // 1) CollectionReference for add/delete
    final artRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('artWorks');

    // 2) Query for listing
    final coll = artRef.orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Art", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.bgpurple,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.backgroundGradientStart,
              AppColors.backgroundGradientEnd
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: coll.snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  "No art yet.\nTap + to create your first piece.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final data = docs[i].data()! as Map<String, dynamic>;
                final base64 = data['base64Image'] as String?;
                final created = data['formattedDate'] as String? ?? '';

                Uint8List? imageBytes;
                if (base64 != null) {
                  imageBytes = base64Decode(base64);
                }

                return Stack(
                  children: [
                    // tappable artwork
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ArtisticExpressionDetailPage(
                              entryId: docs[i].id,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: imageBytes != null
                                  ? Image.memory(
                                imageBytes,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                                  : Container(color: Colors.white10),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            created,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    // delete button
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Delete Artwork?"),
                            content: const Text(
                                "Are you sure you want to delete this artwork?"),
                            backgroundColor: AppColors.bgpurple,
                            titleTextStyle:
                            const TextStyle(color: Colors.white),
                            contentTextStyle:
                            const TextStyle(color: Colors.white70),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text("Cancel",
                                    style: TextStyle(color: Colors.white70)),
                              ),
                              TextButton(
                                onPressed: () async {
                                  // use artRef, not coll
                                  await artRef.doc(docs[i].id).delete();
                                  Navigator.pop(ctx);
                                },
                                child: const Text("Delete",
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete,
                              size: 20, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.bgpurple,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ArtisticExpressionDetailPage(),
            ),
          );
        },
      ),
    );
  }
}
