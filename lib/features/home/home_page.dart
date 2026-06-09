import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('首页', style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('功能开发中', style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
