import 'package:email_validator/email_validator.dart';

class EmailValidatorUtil {
  // Test email domains that should not be used in production
  static const List<String> _testDomains = [
    'test.com',
    'example.com',
    'testing.com',
    'demo.com',
    'sample.com',
    'localhost',
    'mailinator.com',
    'guerrillamail.com',
    'temp-mail.org',
    '10minutemail.com',
  ];

  // Common typo domains that should be corrected
  static const Map<String, String> _commonTypos = {
    'gmial.com': 'gmail.com',
    'gmai.com': 'gmail.com',
    'gmail.co': 'gmail.com',
    'gmali.com': 'gmail.com',
    'yahooo.com': 'yahoo.com',
    'yaho.com': 'yahoo.com',
    'yahoo.co': 'yahoo.com',
    'hotmial.com': 'hotmail.com',
    'hotmai.com': 'hotmail.com',
    'hotmil.com': 'hotmail.com',
    'outlok.com': 'outlook.com',
    'outloo.com': 'outlook.com',
  };

  // Validate email format and domain
  static EmailValidationResult validateEmail(String email) {
    email = email.trim().toLowerCase();

    // Check if email is empty
    if (email.isEmpty) {
      return EmailValidationResult(
        isValid: false,
        error: 'Email address is required',
      );
    }

    // Check basic email format
    if (!EmailValidator.validate(email)) {
      return EmailValidationResult(
        isValid: false,
        error: 'Invalid email format',
      );
    }

    // Extract domain
    final parts = email.split('@');
    if (parts.length != 2) {
      return EmailValidationResult(
        isValid: false,
        error: 'Invalid email format',
      );
    }

    final domain = parts[1];

    // Check for test domains in production
    if (!_isTestMode() && _testDomains.contains(domain)) {
      return EmailValidationResult(
        isValid: false,
        error: 'Please use a valid email address. Test emails are not allowed.',
      );
    }

    // Check for common typos and suggest corrections
    if (_commonTypos.containsKey(domain)) {
      final suggestedDomain = _commonTypos[domain];
      final suggestedEmail = '${parts[0]}@$suggestedDomain';
      return EmailValidationResult(
        isValid: false,
        error: 'Did you mean $suggestedEmail?',
        suggestion: suggestedEmail,
      );
    }

    // Additional checks for suspicious patterns
    if (_isSuspiciousEmail(email)) {
      return EmailValidationResult(
        isValid: false,
        error: 'This email address appears to be invalid',
      );
    }

    return EmailValidationResult(isValid: true);
  }

  // Check if app is in test mode
  static bool _isTestMode() {
    // In debug mode or when using test environment
    const bool isDebug = bool.fromEnvironment('dart.vm.product') == false;
    return isDebug;
  }

  // Check for suspicious email patterns
  static bool _isSuspiciousEmail(String email) {
    // Check for multiple dots in a row
    if (email.contains('..')) return true;

    // Check if email starts or ends with special characters
    final localPart = email.split('@')[0];
    if (localPart.startsWith('.') || localPart.endsWith('.')) return true;
    if (localPart.startsWith('-') || localPart.endsWith('-')) return true;
    if (localPart.startsWith('_') || localPart.endsWith('_')) return true;

    // Check for excessive special characters
    final specialCharCount = RegExp(r'[^a-zA-Z0-9@.]').allMatches(email).length;
    if (specialCharCount > 3) return true;

    // Check for random character strings (potential spam)
    if (_isRandomString(localPart)) return true;

    return false;
  }

  // Detect random character strings
  static bool _isRandomString(String str) {
    // Check if string looks like random characters
    if (str.length > 20) return true;
    
    // Check for too many consonants in a row
    final consonantPattern = RegExp(r'[bcdfghjklmnpqrstvwxyz]{5,}', caseSensitive: false);
    if (consonantPattern.hasMatch(str)) return true;

    // Check for too many numbers
    final numbers = RegExp(r'\d').allMatches(str).length;
    if (numbers > str.length / 2) return true;

    return false;
  }

  // Suggest email domain based on partial input
  static List<String> suggestDomains(String partialDomain) {
    const popularDomains = [
      'gmail.com',
      'yahoo.com',
      'outlook.com',
      'hotmail.com',
      'icloud.com',
      'aol.com',
      'protonmail.com',
      'mail.com',
    ];

    if (partialDomain.isEmpty) return [];

    return popularDomains
        .where((domain) => domain.startsWith(partialDomain.toLowerCase()))
        .toList();
  }
}

class EmailValidationResult {
  final bool isValid;
  final String? error;
  final String? suggestion;

  EmailValidationResult({
    required this.isValid,
    this.error,
    this.suggestion,
  });
}

// Test email generator for development
class TestEmailGenerator {
  static int _counter = 0;

  // Generate a test email that won't bounce
  static String generateTestEmail() {
    _counter++;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Use a domain that you control or a valid test service
    return 'test_${timestamp}_$_counter@mailinator.com';
  }

  // List of valid test emails for development
  static const List<String> validTestEmails = [
    'test.user1@example.com',
    'test.user2@example.com',
    'demo.user@example.com',
    'dev.test@example.com',
  ];

  // Get a random test email
  static String getRandomTestEmail() {
    final index = DateTime.now().millisecond % validTestEmails.length;
    return validTestEmails[index];
  }
}
