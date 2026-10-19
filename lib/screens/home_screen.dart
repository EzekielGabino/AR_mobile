import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:scilense_ar_mobile/components/class_screens/activities_screen.dart';
import 'package:scilense_ar_mobile/components/class_screens/announcement_screen.dart';

class HomeScreen extends StatefulWidget {
  String classId;
  HomeScreen({super.key, required this.classId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth user = FirebaseAuth.instance;
  String classID = '';
  String subject = '';
  String section = '';
  String level = '';

  String teachUid = '';
  @override
  void initState() {
    super.initState();

    classID = widget.classId;

    _getClassInfo();
  }

  Future<void> _getClassInfo() async {
    final doc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(classID)
        .get();

    if (doc.exists) {
      setState(() {
        subject = doc.data()?['subject'] ?? '';
        section = doc.data()?['section_name'] ?? '';
        level = doc.data()?['grade_level'] ?? '';
        teachUid = doc.data()?['teacher_uid'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (teachUid.isEmpty) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('$subject - $section - $level'),
          centerTitle: true,
          automaticallyImplyLeading: false,
          bottom: TabBar(
            tabs: <Widget>[
              Tab(
                child: Text('Stream', style: TextStyle(color: Colors.white)),
              ),
              Tab(
                child: Text(
                  'Activities',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            AnnouncementSection(
              classID: classID,
              user: user,
              teachUid: teachUid,
            ),
            ActivitiesSection(classId: classID),
          ],
        ),
      ),
    );
  }
}
