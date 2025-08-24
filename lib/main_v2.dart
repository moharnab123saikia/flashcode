import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/auth_provider.dart';
import 'providers/flashcard_provider_v2.dart';
import 'providers/study_session_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/study/study_screen.dart';
import 'services/config.dart';
import 'services/local_db_v2.dart';
import 'services/sync_service_v2.dart';
import 'utils/theme.dart';
import 'widgets/sync_conflict_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  
  // Initialize the new persistence system
  await LocalDbV2.instance.init();
  await SyncServiceV2.instance.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initializeAuth()),
        ChangeNotifierProvider(create: (_) => FlashcardProviderV2()),
        ChangeNotifierProvider(create: (_) => StudySessionProvider()),
      ],
      child: MaterialApp(
        title: 'FlashCode',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        routes: {
          '/study': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return StudyScreen(
              initialCards: args?['initialCards'],
              mode: args?['mode'] ?? 'review',
            );
          },
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, FlashcardProviderV2>(
      builder: (context, authProvider, flashcardProvider, child) {
        // Show loading if auth is loading
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Show auth screen if not authenticated
        if (!authProvider.isAuthenticated) {
          return const AuthScreen();
        }
        
        // Initialize flashcard provider with user ID
        if (authProvider.currentUser != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            flashcardProvider.initialize(authProvider.currentUser!.id);
          });
        }
        
        // Check for sync conflicts and show dialog if needed
        if (flashcardProvider.currentConflict != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showConflictDialog(context, flashcardProvider, authProvider.currentUser!.id);
          });
        }
        
        return const HomeScreen();
      },
    );
  }

  void _showConflictDialog(BuildContext context, FlashcardProviderV2 provider, String userId) {
    if (provider.currentConflict == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SyncConflictDialog(
        conflict: provider.currentConflict!,
        onResolve: (resolution) {
          provider.resolveConflict(userId, resolution);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
