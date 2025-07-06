class Validators {
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove any whitespace or special characters except '+'
    String sanitized = value.replaceAll(RegExp(r'\s+'), '');

    // For Indian numbers specifically
    if (sanitized.startsWith('+91')) {
      // Check if it's a valid Indian number (10 digits after +91)
      if (sanitized.length != 13) {
        // +91 + 10 digits
        return 'Please enter a valid Indian phone number';
      }
    } else if (sanitized.startsWith('+')) {
      // For other international numbers
      if (sanitized.length < 8 || sanitized.length > 15) {
        return 'Please enter a valid phone number';
      }
    } else {
      // If no + prefix, assume it's an Indian number
      if (sanitized.length != 10) {
        return 'Please enter a 10-digit phone number';
      }
    }

    return null;
  }

  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }

    if (value.length < 6) {
      return 'OTP must be at least 6 digits';
    }

    return null;
  }
}
