import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class ShareTracker {
  Future<void> trackShare({
    required String userId,
    required String shareType,
    required DateTime timestamp,
    Map<String, dynamic>? metadata,
  });
}

class SupabaseShareTracker implements ShareTracker {
  // Will be implemented once Supabase credentials are provided
  @override
  Future<void> trackShare({
    required String userId,
    required String shareType,
    required DateTime timestamp,
    Map<String, dynamic>? metadata,
  }) async {
    throw UnimplementedError('Supabase implementation pending credentials');
  }
}

class WhatsAppShareService {
  final ShareTracker? tracker;

  WhatsAppShareService({this.tracker});

  Future<void> shareResults({
    required BuildContext context,
    required int score,
    required int totalQuestions,
    required String userId,
  }) async {
    final message = 'I scored $score/$totalQuestions on the K53 test! Try it yourself!';
    final url = 'https://wa.me/?text=${Uri.encodeComponent(message)}';
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
        await tracker?.trackShare(
          userId: userId,
          shareType: 'whatsapp',
          timestamp: DateTime.now(),
          metadata: {'score': score, 'total': totalQuestions},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: ${e.toString()}')),
      );
    }
  }
}