import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/screens/chemistry_screens/chemistry_hub_screen.dart';
import 'package:scilense_ar_mobile/screens/class_screens/notifications_screen.dart';
import 'package:scilense_ar_mobile/screens/home_screen.dart';
import 'package:scilense_ar_mobile/screens/people%20screens/people_screen.dart';
import 'package:scilense_ar_mobile/services/student_notification_service.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

class MainScreen extends StatefulWidget {
  final String classId;
  MainScreen({super.key, this.classId = ''});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedindex = 0;
  String classID = '';
  int _unread = 0;
  int _homeTab = 0;
  int _homeEpoch = 0;

  late List<Widget> screens;

  void switchindex(int screenindex) {
    setState(() {
      selectedindex = screenindex;
    });
  }

  void _openHome({required int tab}) {
    setState(() {
      _homeTab = tab;
      _homeEpoch++;
      selectedindex = 0;
      screens[0] = HomeScreen(
        key: ValueKey('home-$_homeEpoch-$_homeTab'),
        classId: classID,
        initialTab: _homeTab,
      );
    });
  }

  Future<void> _openAlerts() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(
          classId: classID,
          onOpenStream: () {
            Navigator.of(context).pop(); // close alerts
            _openHome(tab: 0);
          },
          onOpenActivities: () {
            Navigator.of(context).pop();
            _openHome(tab: 1);
          },
        ),
      ),
    );
    await _refreshUnread();
  }

  @override
  void initState() {
    super.initState();
    classID = widget.classId;
    _rebuildScreens();
    _refreshUnread();
  }

  void _rebuildScreens() {
    screens = [
      HomeScreen(
        key: ValueKey('home-$_homeEpoch-$_homeTab'),
        classId: classID,
        initialTab: _homeTab,
      ),
      const ChemistryHubScreen(),
      PeopleScreen(classUid: classID),
    ];
  }

  Future<void> _refreshUnread() async {
    try {
      final n = await StudentNotificationService().unreadCount();
      if (mounted) setState(() => _unread = n);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[selectedindex],
      floatingActionButton: FloatingActionButton(
        onPressed: _openAlerts,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Alerts',
        child: Badge(
          isLabelVisible: _unread > 0,
          label: Text('$_unread'),
          child: const Icon(Icons.notifications_outlined),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedindex.clamp(0, 2),
        onTap: switchindex,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Chemistry Hub',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            label: 'Class members',
          ),
        ],
      ),
    );
  }
}
