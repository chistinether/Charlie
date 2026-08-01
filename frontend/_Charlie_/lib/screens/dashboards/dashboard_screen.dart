import 'package:flutter/material.dart';

import '../../models/test_users.dart';

import '../../widgets/voice_nav_fab.dart';

import 'home_page.dart';
import 'expenses_page.dart';
import 'analytics_page.dart';
import 'budgets_page.dart';
import 'profile_page.dart';



class DashboardScreen extends StatefulWidget {

  final TestUser user;


  const DashboardScreen({

    super.key,

    required this.user,

  });



  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();

}





class _DashboardScreenState extends State<DashboardScreen> {


  int selectedIndex = 0;


  late List<Widget> pages;



  @override
  void initState() {

    super.initState();

    loadPages();

  }







  void refreshDashboard() {

    setState(() {

      loadPages();

    });

  }







  void loadPages() {


    pages = [


      HomePage(

        user: widget.user,

        onUpdated: refreshDashboard,

      ),





      ExpensesPage(

        user: widget.user,

        onUpdated: refreshDashboard,

      ),





      AnalyticsPage(

        user: widget.user,

      ),





      BudgetsPage(

        user: widget.user,

      ),





      ProfilePage(

        user: widget.user,

      ),


    ];

  }








  void changePage(int index) {


    setState(() {

      selectedIndex = index;

    });


  }








  @override
  Widget build(BuildContext context) {


    return Scaffold(


      // IndexedStack keeps every tab's widget (and its State) alive in the
      // tree at all times, just hiding the ones that aren't selected.
      // Previously the body swapped straight to `pages[selectedIndex]`,
      // which destroyed and recreated HomePage every time you left the
      // Home tab and came back — causing the welcome popup (and its
      // Gemini API call) to fire again on every single visit.
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),

      // Stays on screen across every tab (it lives outside the
      // IndexedStack), so a visually impaired user always has one
      // consistent, reachable way to navigate the whole app by voice —
      // "open expenses", "open manual budgets", "profile", and so on.
      floatingActionButton: VoiceNavFab(
        user: widget.user,
        onDataChanged: refreshDashboard,
        onSwitchTab: changePage,
      ),




      bottomNavigationBar: BottomNavigationBar(


        currentIndex: selectedIndex,


        onTap: changePage,


        type: BottomNavigationBarType.fixed,



        selectedItemColor:
        const Color(0xFF2E7D32),



        unselectedItemColor:
        Colors.grey,



        items: const [



          BottomNavigationBarItem(

            icon: Icon(Icons.home),

            label: "Home",

          ),




          BottomNavigationBarItem(

            icon: Icon(Icons.payments),

            label: "Expenses",

          ),




          BottomNavigationBarItem(

            icon: Icon(Icons.bar_chart),

            label: "Analytics",

          ),




          BottomNavigationBarItem(

            icon: Icon(Icons.account_balance_wallet),

            label: "Budgets",

          ),




          BottomNavigationBarItem(

            icon: Icon(Icons.person),

            label: "Profile",

          ),



        ],


      ),


    );

  }


}