import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:k53/models/test_session.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:k53/auth_service.dart';
import 'package:k53/models/test_session.dart';
import 'package:k53/services/supabase_service.dart';
import 'package:k53/models/question.dart';
import 'package:k53/services/share_tracker.dart';

class HomeScreen extends StatelessWidget {
  Future<int> _getRemainingAttempts(BuildContext context) async {
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    final userId = auth.currentUser?.id;
    if (userId == null) return 0;
    
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return await supabase.getUserAttemptsToday(userId, today);
  }

  void _showTestHistory(BuildContext context) {
    // Already implemented in the build method
    // Just need to scroll to history section
    final scrollController = PrimaryScrollController.of(context);
    scrollController?.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  final String userId;
  HomeScreen({super.key, required this.userId});

  final WhatsAppShareService _whatsAppShareService = WhatsAppShareService();

  Future<void> _shareViaWhatsApp(BuildContext context) async {
    final userId = Provider.of<AuthService>(context, listen: false).currentUser?.id ?? '';
    // TODO: Get actual test results once available
    await _whatsAppShareService.shareResults(
      context: context,
      score: 0,
      totalQuestions: 0,
      userId: userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('K53 Simulation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              _showTestHistory(context);
            },
            tooltip: 'Test History',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthService>(context, listen: false).signOut(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                if (kDebugMode) {
                  print('Start New Test button pressed');
                }
                final supabase = Provider.of<SupabaseService>(context, listen: false);
                final auth = Provider.of<AuthService>(context, listen: false);
                final userId = auth.currentUser?.id;
                
                if (userId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please login first')),
                  );
                  return;
                }
                
                try {
                  // Check attempts before navigating
                  final today = DateTime.now().toIso8601String().substring(0, 10);
                  final attempts = await supabase.getUserAttemptsToday(userId, today);
                  if (attempts >= 3) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Daily attempt limit reached (3 attempts)')),
                    );
                    return;
                  }
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Provider<SupabaseService>.value(
                        value: supabase,
                        child: const TestSessionScreen(),
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
                      child: const Text('Start New Test'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<int>(
                      future: _getRemainingAttempts(context).then((attempts) => 3 - attempts),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(
                            'Daily attempts remaining: ${3 - (snapshot.data ?? 0)}',
                            style: Theme.of(context).textTheme.titleLarge,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _shareViaWhatsApp(context),
              child: const Text('Share Progress via WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 20),
            Text('Your Progress:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: Provider.of<SupabaseService>(context)
                    .getUserTestHistory(userId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final sessions = snapshot.data!;
                  if (sessions.isEmpty) {
                    return const Text('No test history yet');
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          title: Text('Test ${index + 1}'),
                          subtitle: Text(
                            'Score: ${session['score']}/${session['total_questions']}',
                          ),
                          trailing: Text(
                            '${DateTime.parse(session['start_time']).toLocal().toString().substring(0, 16)}',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TestSessionScreen extends StatefulWidget {
  const TestSessionScreen({super.key});

  @override
  State<TestSessionScreen> createState() => _TestSessionScreenState();
}

class _TestSessionScreenState extends State<TestSessionScreen> {
  int _currentQuestionIndex = 0;
  List<Question> _questions = [];
  bool _isLoadingQuestions = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    if (kDebugMode) {
      print('Starting question load...');
    }
    try {
      final supabase = Provider.of<SupabaseService>(context, listen: false);
      if (kDebugMode) {
        print('Supabase service instance: $supabase');
      }
      final questions = await supabase.getQuestions();
      if (kDebugMode) {
        print('Successfully loaded ${questions.length} questions');
      }
      setState(() {
        _questions = questions;
        _isLoadingQuestions = false;
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Question load failed: $e');
        print(stackTrace);
      }
      setState(() {
        _errorMessage = 'Failed to load questions: ${e.toString()}';
        _isLoadingQuestions = false;
      });
    }
  }

  final Map<String, int?> _userAnswers = {};

  void _answerQuestion(int selectedIndex) {
    setState(() {
      _userAnswers[_questions[_currentQuestionIndex].id] = selectedIndex;
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
      } else {
        // Test completed
        _showResults(context);
      }
    });
  }

  Future<void> _showResults(BuildContext context) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    
    final session = TestSession(
      userId: auth.currentUser?.id ?? '',
      questions: _questions,
      userAnswers: _userAnswers,
    );

    try {
      if (kDebugMode) {
        print('Attempting to save test session...');
      }
      await supabase.saveTestSession(session);
      if (kDebugMode) {
        print('Test session saved successfully');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error saving test session: $e');
        print(stackTrace);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save results: ${e.toString()}')),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        final whatsAppShareService = WhatsAppShareService();
        final userId = Provider.of<AuthService>(context, listen: false).currentUser?.id ?? '';
        
        return AlertDialog(
          title: const Text('Test Completed'),
          content: Text('Your score: ${session.score}/${_questions.length} (${session.percentage.toStringAsFixed(1)}%)'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                whatsAppShareService.shareResults(
                  context: context,
                  score: session.score,
                  totalQuestions: _questions.length,
                  userId: userId,
                );
              },
              child: const Text('Share Results'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingQuestions) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No questions available'),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadQuestions,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(title: Text('Question ${_currentQuestionIndex + 1}/${_questions.length}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (currentQuestion.imagePath != null)
              Image.asset(
                currentQuestion.imagePath!,
                height: 100,
                width: 100,
                fit: BoxFit.contain,
              ),
            Text(
              currentQuestion.text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...currentQuestion.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ElevatedButton(
                  onPressed: () => _answerQuestion(index),
                  child: Text(option),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}