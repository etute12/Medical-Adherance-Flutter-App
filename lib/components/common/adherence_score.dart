import 'package:flutter/material.dart';

class AdherenceScore extends StatelessWidget {
  final int score;
  final bool showTitle;

  const AdherenceScore({
    super.key,
    required this.score,
    this.showTitle = true,
  });

  Color _getAdherenceColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getAdherenceMessage(int score) {
    if (score >= 80) return 'Excellent adherence to medication schedule';
    if (score >= 60) return 'Good adherence, but could be improved';
    return 'Poor adherence, needs attention';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            'Medication Adherence',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
        ],
        LinearProgressIndicator(
          value: score / 100,
          backgroundColor: Colors.grey[300],
          color: _getAdherenceColor(score),
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
        const SizedBox(height: 8),
        Text(
          '$score%',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _getAdherenceColor(score),
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          _getAdherenceMessage(score),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
