import 'package:flutter/foundation.dart' show kIsWeb;

class NetworkConfig {
  // Automatically detect the correct backend URL based on platform
  static String getBackendUrl() {
    // For Web
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    
    // For mobile/desktop, we need to use a different approach
    // Since we can't use dart:io Platform on web, we'll use a simple heuristic
    // This will be called only on non-web platforms
    return _getMobileBackendUrl();
  }
  
  static String _getMobileBackendUrl() {
    // This method is only called on non-web platforms
    // For Android Emulator, use 10.0.2.2
    // For iOS Simulator and others, use localhost
    // You can manually override this by setting a custom URL
    
    // Default to Android Emulator URL
    // Users can change this in the code if needed
    return 'http://10.0.2.2:3000/api';
  }
  
  // Alternative URLs for different scenarios
  static const String web = 'http://localhost:3000/api';
  static const String androidEmulator = 'http://10.0.2.2:3000/api';
  static const String iosSimulator = 'http://localhost:3000/api';
  static const String physicalDevice = 'http://192.168.1.39:3000/api'; // Update with your IP
  
  // Instructions to get your local IP
  static const String ipInstructions = '''
  To find your local IP address:
  
  Windows:
  1. Open Command Prompt
  2. Type: ipconfig
  3. Look for "IPv4 Address" under your active network adapter
  
  Mac/Linux:
  1. Open Terminal
  2. Type: ifconfig
  3. Look for "inet" address (usually starts with 192.168.x.x)
  
  Then update physicalDevice constant with your IP address.
  ''';
}
