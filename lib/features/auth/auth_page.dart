// lib/pages/auth_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';

class AuthPage extends ConsumerWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email')),
            TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                await ref.read(authControllerProvider).signIn(email, password);
              },
              child: const Text('Sign In'),
            ),
            TextButton(
              onPressed: () async {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                await ref.read(authControllerProvider).signUp(email, password);
              },
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
