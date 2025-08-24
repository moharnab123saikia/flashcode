import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as models;
import '../models/user_progress.dart';
import '../utils/email_validator.dart';
import '../services/sync_service_v2.dart';
import '../services/local_db_v2.dart';
import '../services/supabase_service_v2.dart';

enum SyncChoice {
  downloadFromCloud,
  uploadToCloud,
  smartMerge,
  keepLocal,
}

class AuthProvider extends ChangeNotifier {
  models.User? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  // Anki-style sync state
  bool _needsSyncChoice = false;
  SyncConflict? _syncConflict;
  
  models.User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get needsSyncChoice => _needsSyncChoice;
  SyncConflict? get syncConflict => _syncConflict;

  // Initialize auth state from existing session
  Future<void> initializeAuth() async {
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    if (supabaseUser != null) {
      await _createUserFromSupabase(supabaseUser);
    }
  }

  // Create User object from Supabase User
  Future<void> _createUserFromSupabase(User supabaseUser) async {
    _currentUser = models.User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      displayName: supabaseUser.userMetadata?['display_name'] ?? 
                   supabaseUser.email?.split('@').first ?? 'User',
      progress: models.UserProgress(
        totalCardsStudied: 0,
        currentStreak: 0,
        longestStreak: 0,
        grind75Completed: 0,
        categoryProgress: {},
        categoryMastery: {},
        weeklyProgress: {},
      ),
    );
    notifyListeners();
  }

  // Email/Password Sign In with Anki-style sync
  Future<void> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    // Validate email before attempting sign in
    final emailValidation = EmailValidatorUtil.validateEmail(email);
    if (!emailValidation.isValid) {
      _setError(emailValidation.error ?? 'Invalid email address');
      _setLoading(false);
      return;
    }
    
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        await _createUserFromSupabase(response.user!);
        
        // ANKI-STYLE LOGIN SYNC: Check for sync conflicts
        await _performLoginSync(response.user!.id);
      }
    } on AuthException catch (e) {
      _setError(_getReadableErrorMessage(e.message));
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  // Email/Password Sign Up
  Future<void> signUp(String email, String password, String displayName) async {
    _setLoading(true);
    _clearError();
    
    // Validate email before attempting sign up
    final emailValidation = EmailValidatorUtil.validateEmail(email);
    if (!emailValidation.isValid) {
      _setError(emailValidation.error ?? 'Invalid email address');
      _setLoading(false);
      return;
    }
    
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
        },
      );
      
      if (response.user != null) {
        await _createUserFromSupabase(response.user!);
        // Note: User might need to verify email depending on Supabase config
      }
    } on AuthException catch (e) {
      _setError(_getReadableErrorMessage(e.message));
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  // Password Reset
  Future<void> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    
    // Validate email before attempting password reset
    final emailValidation = EmailValidatorUtil.validateEmail(email);
    if (!emailValidation.isValid) {
      _setError(emailValidation.error ?? 'Invalid email address');
      _setLoading(false);
      return;
    }
    
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      // Success - user will receive email
    } on AuthException catch (e) {
      _setError(_getReadableErrorMessage(e.message));
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();
    
    try {
      await Supabase.instance.client.auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError('Error signing out. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  // OAuth Sign In (Google, Apple, etc.)
  Future<void> signInWithOAuth(OAuthProvider provider) async {
    _setLoading(true);
    _clearError();
    
    try {
      await Supabase.instance.client.auth.signInWithOAuth(provider);
      // OAuth redirect will handle the rest
    } on AuthException catch (e) {
      _setError(_getReadableErrorMessage(e.message));
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  // Convenience methods for specific OAuth providers
  Future<void> signInWithGoogle() async {
    await signInWithOAuth(OAuthProvider.google);
  }

  Future<void> signInWithApple() async {
    await signInWithOAuth(OAuthProvider.apple);
  }

  // Convert Supabase error messages to user-friendly text
  String _getReadableErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    } else if (error.contains('Email not confirmed')) {
      return 'Please check your email and click the confirmation link before signing in.';
    } else if (error.contains('User already registered')) {
      return 'An account with this email already exists. Please sign in instead.';
    } else if (error.contains('Password should be at least')) {
      return 'Password must be at least 6 characters long.';
    } else if (error.contains('Unable to validate email address')) {
      return 'Please enter a valid email address.';
    } else if (error.contains('Email rate limit exceeded')) {
      return 'Too many requests. Please wait a moment before trying again.';
    }
    return error; // Return original error if no match
  }

  void updateUserProgress(models.UserProgress progress) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(progress: progress);
      notifyListeners();
    }
  }

  void updateUserSettings(models.UserSettings settings) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(settings: settings);
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // ============================================
  // ANKI-STYLE LOGIN SYNCHRONIZATION
  // ============================================

  /// Perform Anki-style login sync - check for conflicts and handle appropriately
  Future<void> _performLoginSync(String userId) async {
    try {
      debugPrint('🔄 Starting Anki-style login sync for user: $userId');
      
      // Initialize services with web-specific error handling
      try {
        await LocalDbV2.instance.init();
        await SyncServiceV2.instance.init();
      } catch (e) {
        debugPrint('⚠️ V2 services init failed (web limitations): $e');
        // On web, fallback to simpler sync approach
        await _performWebLoginSync(userId);
        return;
      }
      
      // Check for local data
      final localProfile = await LocalDbV2.instance.getUserProfile();
      final localProgress = await LocalDbV2.instance.getAllFlashcardProgress();
      final hasLocalData = localProfile != null || localProgress.isNotEmpty;
      
      // Check for cloud data
      final supabaseService = SupabaseServiceV2.instance;
      final cloudProfile = await supabaseService.getUserProfile(userId);
      final cloudProgress = await supabaseService.getUserFlashcardProgress(userId);
      final hasCloudData = cloudProfile != null || cloudProgress.isNotEmpty;
      
      debugPrint('📊 Sync assessment: Local=$hasLocalData, Cloud=$hasCloudData');
      
      if (!hasLocalData && !hasCloudData) {
        // Case 1: New user - no data anywhere
        debugPrint('✨ New user detected - no sync needed');
        return;
      }
      
      if (!hasLocalData && hasCloudData) {
        // Case 2: Logging in from new device - download cloud data
        debugPrint('⬇️ New device detected - downloading cloud data');
        await SyncServiceV2.instance.downloadProgress(userId);
        return;
      }
      
      if (hasLocalData && !hasCloudData) {
        // Case 3: Local data exists but no cloud data - upload to cloud
        debugPrint('⬆️ Local data found - uploading to cloud');
        await SyncServiceV2.instance.uploadProgress(userId);
        return;
      }
      
      if (hasLocalData && hasCloudData) {
        // Case 4: Both local and cloud data exist - check for conflicts
        debugPrint('⚠️ Both local and cloud data found - checking for conflicts');
        
        final conflict = await _detectLoginConflict(userId, localProfile, localProgress, cloudProfile, cloudProgress);
        
        if (conflict != null) {
          // Present conflict resolution options to user
          _syncConflict = conflict;
          _needsSyncChoice = true;
          debugPrint('🚨 Setting sync conflict state: needsSyncChoice=$_needsSyncChoice');
          debugPrint('📊 Conflict details: Local streak=${conflict.localProfile?.currentStreak}, Cloud streak=${conflict.cloudProfile?.currentStreak}');
          notifyListeners();
          debugPrint('🔔 AuthProvider notifyListeners() called for sync conflict');
        } else {
          // No real conflict, perform automatic sync
          debugPrint('✅ No conflicts detected - performing automatic sync');
          await SyncServiceV2.instance.autoSync(userId);
        }
      }
      
    } catch (e) {
      debugPrint('❌ Login sync failed: $e');
      // Don't show error to user for sync issues during login
      debugPrint('🔄 Continuing with basic login - sync will retry later');
    }
  }

  /// Simplified web-compatible login sync
  Future<void> _performWebLoginSync(String userId) async {
    try {
      debugPrint('🌐 Performing web-compatible login sync');
      
      // Check for cloud data only (web has limited local storage)
      final supabaseService = SupabaseServiceV2.instance;
      final cloudProfile = await supabaseService.getUserProfile(userId);
      final cloudProgress = await supabaseService.getUserFlashcardProgress(userId);
      final hasCloudData = cloudProfile != null || cloudProgress.isNotEmpty;
      
      if (hasCloudData) {
        debugPrint('📥 Cloud data found - will be loaded by FlashcardProviderV2');
        // Let the FlashcardProviderV2 handle the data loading
        // This is sufficient for web where local storage is limited
      } else {
        debugPrint('✨ New user on web - no cloud data to sync');
      }
      
    } catch (e) {
      debugPrint('❌ Web login sync failed: $e');
      // Continue anyway - this is not critical for login
    }
  }

  /// Detect conflicts specifically during login
  /// ONLY for flashcard progress - profile data always uses cloud as source
  Future<SyncConflict?> _detectLoginConflict(
    String userId,
    UserProfile? localProfile,
    List<FlashcardProgress> localProgress,
    UserProfile? cloudProfile,
    List<FlashcardProgress> cloudProgress,
  ) async {
    // NEVER conflict on profile data - cloud is always authoritative
    // ONLY check flashcard progress for conflicts
    
    if (localProgress.isEmpty || cloudProgress.isEmpty) {
      return null; // No conflict if either side has no progress
    }
    
    bool hasProgressConflict = false;
    
    // Create maps for efficient lookup
    final localProgressMap = {for (var p in localProgress) p.flashcardId: p};
    final cloudProgressMap = {for (var p in cloudProgress) p.flashcardId: p};
    
    // Check for meaningful progress differences
    for (final flashcardId in {...localProgressMap.keys, ...cloudProgressMap.keys}) {
      final localProg = localProgressMap[flashcardId];
      final cloudProg = cloudProgressMap[flashcardId];
      
      // Only conflict if card exists on both sides with significant differences
      if (localProg != null && cloudProg != null) {
        if ((localProg.reviewCount - cloudProg.reviewCount).abs() > 2 ||
            localProg.personalDifficulty != cloudProg.personalDifficulty ||
            _daysDifference(localProg.lastReviewedAt, cloudProg.lastReviewedAt) > 3) {
          hasProgressConflict = true;
          debugPrint('Login progress conflict detected for card $flashcardId');
          break;
        }
      }
    }
    
    if (hasProgressConflict) {
      return SyncConflict(
        localProfile: localProfile,
        cloudProfile: cloudProfile, // Cloud profile will be used regardless
        localProgress: localProgress,
        cloudProgress: cloudProgress,
      );
    }
    
    return null;
  }

  /// Handle user's sync choice (called from UI)
  Future<void> handleSyncChoice(SyncChoice choice) async {
    if (!_needsSyncChoice || _currentUser == null) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      final userId = _currentUser!.id;
      
      switch (choice) {
        case SyncChoice.downloadFromCloud:
          debugPrint('📥 User chose: Download from cloud');
          await SyncServiceV2.instance.downloadProgress(userId);
          break;
          
        case SyncChoice.uploadToCloud:
          debugPrint('📤 User chose: Upload to cloud');
          await SyncServiceV2.instance.uploadProgress(userId);
          break;
          
        case SyncChoice.smartMerge:
          debugPrint('🧠 User chose: Smart merge');
          await SyncServiceV2.instance.resolveConflict(userId, ConflictResolution.smartMerge);
          break;
          
        case SyncChoice.keepLocal:
          debugPrint('💾 User chose: Keep local data');
          await SyncServiceV2.instance.uploadProgress(userId);
          break;
      }
      
      // Clear sync choice state
      _needsSyncChoice = false;
      _syncConflict = null;
      notifyListeners();
      
      debugPrint('✅ Sync choice completed successfully');
      
    } catch (e) {
      debugPrint('❌ Sync choice failed: $e');
      _setError('Failed to sync data: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Cancel sync choice and continue with local data
  void cancelSyncChoice() {
    _needsSyncChoice = false;
    _syncConflict = null;
    notifyListeners();
    debugPrint('🚫 User cancelled sync choice - continuing with local data');
  }

  /// Get a user-friendly description of the sync conflict
  String getSyncConflictDescription() {
    if (_syncConflict == null) return '';
    
    final summary = _syncConflict!.toSummary();
    final local = summary['local'] as Map<String, dynamic>;
    final cloud = summary['cloud'] as Map<String, dynamic>;
    
    return '''
Local Device:
• ${local['progressCount']} cards studied
• ${local['currentStreak']} day streak
• ${local['cardsStudiedToday']} cards studied today

Cloud:
• ${cloud['progressCount']} cards studied  
• ${cloud['currentStreak']} day streak
• ${cloud['cardsStudiedToday']} cards studied today

Choose how to resolve this conflict:''';
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  int _daysDifference(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return 0;
    return (date1.difference(date2).inDays).abs();
  }
}
