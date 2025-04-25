import 'package:flutter/material.dart';

class AdherenceScore extends StatelessWidget {
  final int score;
  final bool showTitle;
  final bool showDetails;

  const AdherenceScore({
    super.key,
    required this.score,
    this.showTitle = true,
    this.showDetails = true,
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

  String _getAdherenceDetails(int score) {
    if (score >= 80) {
      return 'Patient is taking medications consistently and on time. Continue with current regimen.';
    } else if (score >= 60) {
      return 'Patient is taking most medications but may be missing some doses or taking them late. Consider discussing any challenges they may be facing.';
    } else {
      return 'Patient is missing many doses or taking medications very inconsistently. Immediate intervention recommended to identify and address barriers.';
    }
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
        if (showDetails) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getAdherenceColor(score).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _getAdherenceColor(score).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adherence Analysis',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: _getAdherenceColor(score),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getAdherenceDetails(score),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
