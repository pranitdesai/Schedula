import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:schedula/HomeScreen/task_card.dart';
import 'package:schedula/Utils/app_color.dart';
import 'package:schedula/custom_widget/snack_bar.dart';

import '../Authentication/login_screen.dart';
import '../Diet/diet_modal.dart';
import '../ManageProjectScreen/manage_project_screen.dart';
import '../ScheduleDisplay/daily_schedule.dart';
import '../ScheduleDisplay/weekly_schedule.dart';
import 'db_data_getter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<String> _fetchNameFuture;

  bool _nameLoaded = false;
  bool _projectsLoaded = false;

  static final DateFormat _monthFormat = DateFormat('MMM');
  static final DateFormat _dayOfWeekFormat = DateFormat('EEE');

  late final TextStyle dateStyle = GoogleFonts.poppins(
    fontSize: 18,
    color: Colors.black,
    fontWeight: FontWeight.w300,
  );

  late final TextStyle helloStyle = GoogleFonts.poppins(
    fontSize: 20,
    color: Colors.black,
    fontWeight: FontWeight.w400,
  );

  late final TextStyle nameStyle = GoogleFonts.poppins(
    fontSize: 20,
    color: AppColor.green700,
    fontWeight: FontWeight.w600,
  );

  late final TextStyle subtitleStyle = GoogleFonts.poppins(
    fontSize: 16,
    color: Colors.black,
    fontWeight: FontWeight.w300,
  );

  final user = FirebaseAuth.instance.currentUser!;
  late final DatabaseReference dbRef = FirebaseDatabase.instance
      .ref()
      .child("projects")
      .child(user.uid);

  @override
  void initState() {
    super.initState();
    _fetchNameFuture = DataGetter.getName();
  }

  String getDayDate() {
    final now = DateTime.now();
    return "${_dayOfWeekFormat.format(now)}, ${_monthFormat.format(now)} ${now.day} ${now.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.green100,
      drawer: const _HomeScreenDrawer(),
      body: Stack(
        children: [
          /// MAIN UI
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  /// HEADER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Builder(
                                  builder: (context) {
                                    return InkWell(
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () =>
                                          Scaffold.of(context).openDrawer(),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: HugeIcon(
                                          icon: HugeIcons.strokeRoundedMenu01,
                                          size: 28,
                                          color: AppColor.green700,
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(width: 50),

                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Text(getDayDate(), style: dateStyle),
                                ),
                              ],
                            ),

                            /// USER NAME
                            FutureBuilder<String>(
                              future: _fetchNameFuture,
                              builder: (context, snapshot) {
                                if (snapshot.hasData && !_nameLoaded) {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted) {
                                      setState(() => _nameLoaded = true);
                                    }
                                  });
                                }

                                if (!snapshot.hasData) return const SizedBox();

                                return Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Hello, ',
                                        style: helloStyle,
                                      ),
                                      TextSpan(
                                        text: snapshot.data!,
                                        style: nameStyle,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            Text('Have a nice day', style: subtitleStyle),
                          ],
                        ),

                        /// PROFILE BUTTON
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              width: 60,
                              height: 120,
                              decoration: const BoxDecoration(
                                color: AppColor.green700,
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(80),
                                ),
                              ),
                            ),
                            const Positioned(
                              bottom: 8,
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white,
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedUserList,
                                  color: AppColor.green700,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// MAIN CONTAINER
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),

                          Text(
                            'Projects',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          /// PROJECT LIST
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 12),
                            child: StreamBuilder(
                              stream: dbRef.onValue,
                              builder: (context, snapshot) {
                                if (snapshot.hasData && !_projectsLoaded) {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted) {
                                      setState(() => _projectsLoaded = true);
                                    }
                                  });
                                }

                                if (!snapshot.hasData ||
                                    snapshot.data!.snapshot.value == null) {
                                  return const SizedBox();
                                }

                                Map data = snapshot.data!.snapshot.value as Map;
                                List projectList = data.values.toList();

                                Map<String, int> statusPriority = {
                                  "in progress": 0,
                                  "pending": 1,
                                  "completed": 2,
                                };

                                projectList.sort((a, b) {
                                  String statusA = (a["status"] ?? "pending")
                                      .toString()
                                      .toLowerCase();
                                  String statusB = (b["status"] ?? "pending")
                                      .toString()
                                      .toLowerCase();

                                  return (statusPriority[statusA] ?? 3)
                                      .compareTo(statusPriority[statusB] ?? 3);
                                });

                                return SizedBox(
                                  height: 150,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 12,
                                    ),
                                    itemCount: projectList.length,
                                    itemBuilder: (context, index) {
                                      final project = projectList[index];

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        child: TaskCard(
                                          title: project["name"] ?? "No Title",
                                          category:
                                              project["status"] ?? "pending",
                                          date: project["startDate"] != null
                                              ? DateFormat('dd MMM yy').format(
                                                  DateTime.parse(
                                                    project["startDate"],
                                                  ),
                                                )
                                              : "",
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 16),
                          const _WeeklyScheduleCard(),
                          const SizedBox(height: 16),
                          const _DailyScheduleCard(),
                          const SizedBox(height: 16),
                          const _ManageProjectCard(),
                          const SizedBox(height: 16),
                          const _CreateTaskCard(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// SHIMMER LOADER
          if (!_nameLoaded || !_projectsLoaded) const _HomeShimmerLoader(),
        ],
      ),
    );
  }
}

class _HomeScreenDrawer extends StatelessWidget {
  const _HomeScreenDrawer();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Drawer(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: const [
                  // SizedBox(height: 8),
                  // _HomeTile(icon: HugeIcons.strokeRoundedHome03, title: 'Home'),
                  // _HomeTile(
                  //   icon: HugeIcons.strokeRoundedUser,
                  //   title: 'Profile',
                  //   route: '/profile',
                  // ),
                  // _HomeTile(
                  //   icon: HugeIcons.strokeRoundedServingFood,
                  //   title: 'Diet Plan',
                  //   route: '/diet_plan',
                  SizedBox.expand()

                ],
              ),
            ),
            const _LogoutButton(),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: InkWell(
        onTap: () async => _showLogoutDialog(context),
        splashColor: AppColor.errorRipple,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
          decoration: BoxDecoration(
            color: AppColor.error,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              "Logout",
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.black45),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.black, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(color: Colors.red, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String? route;
  const _HomeTile({required this.icon, required this.title, this.route});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: HugeIcon(icon: icon, color: Colors.black, size: 28),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 18, color: Colors.black),
      ),
      onTap: () {
        Navigator.pop(context);
        if (route != null) Navigator.pushNamed(context, route!);
      },
    );
  }
}

/// SHIMMER UI
class _HomeShimmerLoader extends StatelessWidget {
  const _HomeShimmerLoader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- TOP APP BAR AREA ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Menu Icon
                    Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.symmetric(vertical: 14),
                          color: Colors.white,
                        ),
                      ],
                    ),
                    // Date
                    Container(
                      width: 130,
                      height: 20,
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    // Profile Picture
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          width: 60,
                          height: 120,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(80),
                            ),
                          ),
                        ),

                        const Positioned(
                          bottom: 8,
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // --- GREETING ---
                Container(width: 220, height: 28, color: Colors.white),
                const SizedBox(height: 8),
                Container(width: 140, height: 16, color: Colors.white),
                const SizedBox(height: 32),

                // --- PROJECTS SECTION ---
                Container(width: 100, height: 24, color: Colors.white),
                const SizedBox(height: 16),

                // Horizontal Cards
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // --- VERTICAL TASKS SECTION ---
                Expanded(
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return Container(
                        height: 85,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateTaskCard extends StatelessWidget {
  const _CreateTaskCard();
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        CustomSnackBar.show(
          context,
          message: 'Soon in service',
          type: SnackBarType.info,
          fromTop: false,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Create new task",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  "You can create new task in here",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              child: Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedAdd01,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManageProjectCard extends StatelessWidget {
  const _ManageProjectCard();
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, _fadeRouteBuilder(const ManageProjectScreen()));
      },
      child: Hero(
        transitionOnUserGestures: true,
        tag: 'manageProject',
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            height: 86,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Manage projects",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "You can manage your projects in here",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  child: Container(
                    width: 36,
                    height: 36,
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedFolderManagement,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeeklyScheduleCard extends StatelessWidget {
  const _WeeklyScheduleCard();
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          _fadeRouteBuilder(const WeeklyScheduleScreen()),
        );
      },
      child: Hero(
        transitionOnUserGestures: true,
        tag: 'weeklySchedule',
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            height: 86,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Check weekly schedule",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Check your predefined schedule",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  child: Container(
                    width: 36,
                    height: 36,
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedBook02,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyScheduleCard extends StatelessWidget {
  const _DailyScheduleCard();
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, _fadeRouteBuilder(const DailyScheduleScreen()));
      },
      child: Hero(
        transitionOnUserGestures: true,
        tag: 'dailySchedule',
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            height: 75,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Check daily schedule",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Check your predefined daily schedule",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  child: Container(
                    width: 36,
                    height: 36,
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedBookOpen02,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

PageRouteBuilder _fadeRouteBuilder(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 500),
    reverseTransitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
  );
}
