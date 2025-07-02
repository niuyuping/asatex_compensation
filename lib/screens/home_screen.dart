import 'package:asatex_compensation/screens/gross_salary_calculator_screen.dart';
import 'package:asatex_compensation/screens/salary_calculator_screen.dart';
import 'package:asatex_compensation/screens/settings_screen.dart';
import 'package:asatex_compensation/screens/tanka_calculator_screen.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    SalaryCalculatorScreen(title: '給与計算'),
    GrossSalaryCalculatorScreen(title: '基本給逆算'),
    TankaCalculatorScreen(title: '単価逆算'),
    SettingsScreen(title: '設定'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: '給与計算',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: '基本給逆算',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: '単価逆算',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // This is important for 4+ items
      ),
    );
  }
} 