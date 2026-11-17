import 'dart:convert';
import 'package:http/http.dart' as http;

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
  
    final questions = <QuizQuestion>[];
    final answers = <String?>[];

    int questionIndex = 0;
    int score = 0;

    String roundId = '';
    String message = 'Press Start to begin.';

    bool loading = false;
    bool answered = false;
    bool finished = false;
    bool submitting = false;

    DateTime? lastRequest;
    
Future<void> loadQuestions() async {
  setState(() {
    loading = true;
    message = 'Loading questions...';
  });

  try {
    final response = await http.get(
      Uri.parse(
        'https://opentdb.com/api.php?amount=10&category=9&difficulty=easy&type=multiple',
      ),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Could not load questions');
    }

    final data = jsonDecode(response.body);

    if (data['response_code'] != 0 ||
        data['results'].length != 10) {
      throw Exception('Invalid questions');
    }

    questions.clear();

    for (final item in data['results']) {
      final correct = decodeHtml(item['correct_answer'].toString());
      final incorrectAnswers = (item['incorrect_answers'] as List<dynamic>)
          .map<String>((answer) => decodeHtml(answer.toString()));

      final choices = <String>[correct, ...incorrectAnswers]
        ..shuffle();

      questions.add(
        QuizQuestion(
          question: decodeHtml(item['question'].toString()),
          correctAnswer: correct,
          choices: choices,
        ),
      );
    }

    answers.clear();
    answers.addAll(List<String?>.filled(10, null));

    setState(() {
      loading = false;
      message = 'Choose your answer.';
    });
  } catch (e) {
    setState(() {
      loading = false;
      message = 'Could not load questions. Try again.';
    });
  }
}

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome ${widget.user.email ?? 'User'}'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: widget.onComplete,
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