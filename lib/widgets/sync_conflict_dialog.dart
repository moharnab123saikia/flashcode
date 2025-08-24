import 'package:flutter/material.dart';
import '../services/sync_service_v2.dart';

class SyncConflictDialog extends StatelessWidget {
  final SyncConflict conflict;
  final Function(ConflictResolution) onResolve;

  const SyncConflictDialog({
    super.key,
    required this.conflict,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.sync_problem, color: Colors.orange),
          SizedBox(width: 8),
          Text('Sync Conflict'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your progress conflicts with data on another device. How would you like to resolve this?',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildConflictDetails(context),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () => onResolve(ConflictResolution.useLocal),
          icon: const Icon(Icons.phone_android),
          label: const Text('Use This Device'),
        ),
        TextButton.icon(
          onPressed: () => onResolve(ConflictResolution.useCloud),
          icon: const Icon(Icons.cloud),
          label: const Text('Use Cloud Data'),
        ),
        ElevatedButton.icon(
          onPressed: () => onResolve(ConflictResolution.smartMerge),
          icon: const Icon(Icons.merge),
          label: const Text('Smart Merge'),
        ),
      ],
    );
  }

  Widget _buildConflictDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conflict Details:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          _buildDetailRow('Type:', 'Progress Conflict'),
          _buildDetailRow('Local Progress:', '${conflict.localProgress.length} cards'),
          _buildDetailRow('Cloud Progress:', '${conflict.cloudProgress.length} cards'),
          _buildDetailRow('Detected:', _formatDateTime(conflict.conflictDetectedAt)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
