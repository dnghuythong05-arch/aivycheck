import 'package:flutter/material.dart';

class SalaryScreen extends StatelessWidget {
  const SalaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F8FE),
        title: const Text('Bảng lương'),
      ),
      body: const Center(
        child: Text('Trống', style: TextStyle(fontSize: 20, color: Color(0xFF64748B))),
      ),
    );
  }
}
