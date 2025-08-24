import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';

class LoginSyncDialog extends StatelessWidget {
  final AuthProvider authProvider;
  final VoidCallback onResolved;

  const LoginSyncDialog({
    Key? key,
    required this.authProvider,
    required this.onResolved,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.sync_problem, color: theme.colorScheme.warning),
          const SizedBox(width: 12),
          const Text('Sync Conflict Detected'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We found different flashcard progress on this device and in the cloud.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                authProvider.getSyncConflictDescription(),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'How would you like to resolve this?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: () {
            authProvider.cancelSyncChoice();
            Navigator.of(context).pop();
            onResolved();
          },
          child: const Text('Skip Sync'),
        ),
        
        // Sync options
        FilledButton.tonal(
          onPressed: () => _handleChoice(context, SyncChoice.downloadFromCloud),
          child: const Text('Use Cloud Data'),
        ),
        FilledButton.tonal(
          onPressed: () => _handleChoice(context, SyncChoice.uploadToCloud),
          child: const Text('Use Local Data'),
        ),
        FilledButton(
          onPressed: () => _handleChoice(context, SyncChoice.smartMerge),
          child: const Text('Smart Merge'),
        ),
      ],
    );
  }

  void _handleChoice(BuildContext context, SyncChoice choice) async {
    Navigator.of(context).pop();
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _SyncProgressDialog(),
    );
    
    try {
      await authProvider.handleSyncChoice(choice);
      Navigator.of(context).pop(); // Close loading dialog
      onResolved();
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sync Error'),
          content: Text('Failed to sync data: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

class _SyncProgressDialog extends StatelessWidget {
  const _SyncProgressDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 16),
          const Text('Syncing your flashcard progress...'),
        ],
      ),
    );
  }
}

/// Helper extension for theme colors
extension on ColorScheme {
  Color get warning => const Color(0xFFFF9800);
}
