// FlashCode Hybrid V1/V2 Entry Point
// This version uses V2 architecture while maintaining V1 compatibility

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// V2 System Imports
import 'models/user_progress.dart';
import 'providers/flashcard_provider_v2.dart';
import 'services/supabase_service_v2.dart';
import 'services/local_db_v2.dart'
    if (dart.library.html) 'services/local_db_v2_web.dart';
import 'services/sync_service_v2.dart';

// V1 Providers (for compatibility)
import 'providers/auth_provider.dart';
import 'providers/study_session_provider.dart';

// Screens (V1 - will gradually migrate)
import 'screens/home/home_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/study/study_screen.dart';
import 'utils/theme.dart';
import 'services/config.dart';

// Get config values
const supabaseUrl = AppConfig.supabaseUrl;
const supabaseAnonKey = AppConfig.supabaseAnonKey;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Initialize V2 services - catch web-specific errors gracefully
  try {
    await LocalDbV2.instance.init();
    await SyncServiceV2.instance.init();
    debugPrint('✅ V2 services initialized successfully');
  } catch (e) {
    debugPrint('⚠️ V2 services initialization failed (this is expected on web): $e');
    // Continue anyway - web will use alternative storage
  }
  
  runApp(const FlashCodeHybridApp());
}

class FlashCodeHybridApp extends StatelessWidget {
  const FlashCodeHybridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // V1 Providers (maintaining compatibility)
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StudySessionProvider()),
        
        // V2 Providers (new architecture) - FlashcardProvider is now V2
        ChangeNotifierProvider(create: (_) => FlashcardProviderV2()),
      ],
      child: MaterialApp(
        title: 'FlashCode V2',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/study':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => StudyScreen(
                  initialCards: args?['initialCards'],
                  mode: args?['mode'] ?? 'review',
                ),
              );
            default:
              return MaterialPageRoute(
                builder: (context) => const AuthWrapper(),
              );
          }
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasInitializedContent = false;
  bool _hasInitializedUser = false;
  String _lastUserId = '';

  @override
  void initState() {
    super.initState();
    // Initialize V2 system content (without user-specific data)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeV2Content();
    });
  }

  void _initializeV2Content() async {
    if (_hasInitializedContent) return;
    _hasInitializedContent = true;
    
    try {
      // Ensure database is initialized first
      await LocalDbV2.instance.init();
      // Initialize content only (flashcard data) without user ID
      await context.read<FlashcardProviderV2>().syncFlashcardContent();
      debugPrint('V2 system initialized for flashcard content');
    } catch (e) {
      debugPrint('Error initializing V2 content: $e');
    }
  }

  void _initializeUserData(String userId) async {
    if (_hasInitializedUser && _lastUserId == userId) return;
    _hasInitializedUser = true;
    _lastUserId = userId;
    
    try {
      // Initialize with specific user ID for user-specific data
      await context.read<FlashcardProviderV2>().initialize(userId);
      debugPrint('V2 system initialized for user: $userId');
    } catch (e) {
      debugPrint('Error initializing V2 user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isAuthenticated) {
          final userId = authProvider.currentUser?.id ?? '';
          if (userId.isNotEmpty) {
            // Initialize user-specific data
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initializeUserData(userId);
            });
          }
          
          return const HomeScreen();
        } else {
          // Reset user initialization when logged out
          _hasInitializedUser = false;
          _lastUserId = '';
          return const AuthScreen();
        }
      },
    );
  }
}
