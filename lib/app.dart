import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return const SignInScreen();
          }
          return QuizScreen(user: user, onComplete: onComplete);
        },
      ),
    );
  }
}

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email = TextEditingController();
    final password = TextEditingController();

    return Scaffold(
      body: Column(
        children: [
          const Text('Email'),
          TextField(controller: email),
          const Text('Password'),
          TextField(controller: password, obscureText: true),
          ElevatedButton(
            onPressed: () => FirebaseAuth.instance.signInWithEmailAndPassword(
              email: email.text,
              password: password.text,
            ),
            child: const Text('Sign In'),
          ),
          ElevatedButton(
            onPressed: () => FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: email.text,
              password: password.text,
            ),
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }
}

String decodeHtml(String text) {
  const replacements = {
    '&quot;': '"',
    '&#039;': "'",
    '&apos;': "'",
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
  };

  replacements.forEach((key, value) {
    text = text.replaceAll(key, value);
  });

  return text;
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.user,
    required this.onComplete,
  });

  final User user;
  final VoidCallback onComplete;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final onComplete = widget.onComplete;

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome ${user.email ?? 'User'}'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: onComplete,
          child: const Text('Complete Quiz'),
        ),
      ),
    );
  }
}

class QuizQuestion {
  QuizQuestion({
    required this.question,
    required this.correctAnswer,
    required this.choices,
  });

  final String question;
  final String correctAnswer;
  final List<String> choices;
}