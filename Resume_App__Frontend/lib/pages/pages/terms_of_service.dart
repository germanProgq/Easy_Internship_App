import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: const Center(
        child: Text(
          'Terms of Service Content Goes Here.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
