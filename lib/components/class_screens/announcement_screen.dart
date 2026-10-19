import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AnnouncementSection extends StatefulWidget {
  const AnnouncementSection({
    super.key,
    required this.classID,
    required this.user,
    required this.teachUid,
  });

  final String classID;
  final FirebaseAuth user;
  final String teachUid;

  @override
  State<AnnouncementSection> createState() => _AnnouncementSectionState();
}

class _AnnouncementSectionState extends State<AnnouncementSection> {
  String teachName = '';
  String teachPhoto = '';

  @override
  void initState() {
    super.initState();
    _getTeacherDetails();
  }

  Future<void> _getTeacherDetails() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.teachUid)
        .get();

    if (!mounted) return;

    if (doc.exists) {
      final data = doc.data();

      setState(() {
        teachName = data?['name'] ?? '';
        teachPhoto = data?['photoUrl'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classID)
          .collection('announcements')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text('No announcements yet.'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, index) {
            final data = docs[index].data() as Map<String, dynamic>;

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          if (teachPhoto.isNotEmpty)
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(teachPhoto),
                            ),

                          const SizedBox(width: 10),

                          Text(
                            teachName.isNotEmpty ? teachName : 'Teacher',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    ListTile(
                      title: Text(
                        data['text'] ?? '',
                        style: const TextStyle(fontSize: 15),
                      ),
                      subtitle: Text(
                        'Posted At: ${data['postedAt'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
