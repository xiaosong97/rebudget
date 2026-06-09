import 'package:flutter/material.dart';

void main() {
  runApp(const RebudgetApp());
}

class RebudgetApp extends StatelessWidget {
  const RebudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '复账',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MainShellPage(),
    );
  }
}

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;

  static const List<_NavigationItem> _items = [
    _NavigationItem(
      title: '首页',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      page: PlaceholderPage(title: '首页'),
    ),
    _NavigationItem(
      title: '账单',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      page: PlaceholderPage(title: '账单'),
    ),
    _NavigationItem(
      title: '预算',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
      page: PlaceholderPage(title: '预算'),
    ),
    _NavigationItem(
      title: '统计',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      page: PlaceholderPage(title: '统计'),
    ),
    _NavigationItem(
      title: '我的',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      page: PlaceholderPage(title: '我的'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentItem = _items[_currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text(currentItem.title), centerTitle: true),
      body: IndexedStack(
        index: _currentIndex,
        children: _items.map((item) => item.page).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: _items
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.title,
              ),
            )
            .toList(),
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('功能开发中', style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _NavigationItem {
  const _NavigationItem({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });

  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}
