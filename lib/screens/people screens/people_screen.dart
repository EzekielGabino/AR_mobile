import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/screens/people%20screens/profile_screen.dart';
import 'package:scilense_ar_mobile/services/classroom_service.dart';

class PeopleScreen extends StatefulWidget {
  String classUid;
  PeopleScreen({super.key, required this.classUid});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  String classID = '';
  String teachName = '';
  String teachPhoto = '';
  String teachUid = '';
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    classID = widget.classUid;
    _getClassDetails();
  }

  Future<void> _getClassDetails() async {
    final doc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(classID)
        .get();

    if (doc.exists) {
      setState(() {
        teachUid = doc.data()?['teacher_uid'] ?? '';
      });

      if (teachUid.isNotEmpty) {
        _getTeacherDetails();
      }
    }
  }

  Future<void> _getTeacherDetails() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(teachUid)
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

  Future<DocumentSnapshot<Map<String, dynamic>>> getStudentDetails(
    String uid,
  ) async {
    return await FirebaseFirestore.instance.collection('users').doc(uid).get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("People"),
        centerTitle: true,
        actions: [
          if (auth.currentUser != null)
            GestureDetector(
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => ProfileScreen())),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(auth.currentUser!.photoURL!),
              ),
            ),
          SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Teacher", style: TextStyle(fontSize: 25)),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: teachPhoto.isNotEmpty
                          ? NetworkImage(teachPhoto)
                          : null,
                    ),
                    SizedBox(width: 10),
                    Text(teachName, style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),
            Text("Students", style: TextStyle(fontSize: 25)),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('classes')
                    .doc(classID)
                    .snapshots(),
                builder: (_, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text('Class not found'));
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;

                  final students = data['students'] as List<dynamic>? ?? [];

                  if (students.isEmpty) {
                    return const Center(child: Text('No Students yet'));
                  }

                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (_, index) {
                      final student = students[index] as Map<String, dynamic>;

                      return FutureBuilder<
                        DocumentSnapshot<Map<String, dynamic>>
                      >(
                        future: getStudentDetails(student['uid']),
                        builder: (_, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  'Firebase Error: ${snapshot.error}',
                                ),
                              ),
                            );
                          }

                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return const Card(
                              child: ListTile(title: Text('Student not found')),
                            );
                          }

                          final user = snapshot.data!.data();

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage:
                                        user?['photoUrl'] != null &&
                                            user!['photoUrl']
                                                .toString()
                                                .isNotEmpty
                                        ? NetworkImage(user['photoUrl'])
                                        : null,
                                    child: user?['photoUrl'] == null
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    user?['fullName'] ?? 'Unknown Student',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
