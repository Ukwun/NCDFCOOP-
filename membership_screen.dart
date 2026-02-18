import 'package:flutter/material.dart';

class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Member Exclusives'), centerTitle: true),
      body: const Center(child: Text('Member Exclusives Screen')),
    );
  }
}
