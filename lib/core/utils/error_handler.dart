import 'package:firebase_auth/firebase_auth.dart';

class ErrorHandler {
  static String getFriendlyMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Invalid email or password. Please try again.';
        case 'email-already-in-use':
          return 'An account already exists with that email.';
        case 'weak-password':
          return 'Please choose a stronger password (at least 6 characters).';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled. Please contact support.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return 'An authentication error occurred. Please try again.';
      }
    } else if (error is FirebaseException) {
      switch (error.code) {
        case 'unavailable':
          return 'Service is temporarily unavailable. Please try again later.';
        case 'permission-denied':
          return 'You do not have permission to perform this action.';
        default:
          return 'A server error occurred. Please try again.';
      }
    } else if (error is Exception) {
      final msg = error.toString();
      if (msg.contains('Location')) {
        return 'Could not retrieve your location. Please ensure GPS is enabled and permissions are granted.';
      } else if (msg.contains('Exception:')) {
        return msg.replaceFirst('Exception: ', '').trim();
      }
      return 'An unexpected error occurred. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }
}
