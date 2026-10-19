import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/screens/chemistry_screens/chemistry_hub_screen.dart';
import 'package:scilense_ar_mobile/screens/home_screen.dart';
import 'package:scilense_ar_mobile/screens/people%20screens/people_screen.dart';

class MainScreen extends StatefulWidget {
  final String classId;
  MainScreen({super.key, this.classId = ''});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedindex = 0;
  String classID = '';

  List<Widget> screens = [];

  void switchindex(int screenindex) {
    setState(() {
      selectedindex = screenindex;
    });
  }

  @override
  void initState() {
    super.initState();
    classID = widget.classId;

    screens = [
      HomeScreen(classId: classID),
      ChemistryHubScreen(),
      PeopleScreen(classUid: classID),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[selectedindex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedindex,
        onTap: switchindex,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: "Experiments",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt),
            label: "People",
          ),
        ],
      ),
    );
  }
}
