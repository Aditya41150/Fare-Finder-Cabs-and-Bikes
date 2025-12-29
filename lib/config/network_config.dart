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
    // Updated for physical device (Moto G84 5G)
    // Using computer's WiFi IP address: 192.168.1.33
    
    // For physical device - using your computer's IP
    return physicalDevice;
  }
  
  // Alternative URLs for different scenarios
  static const String web = 'http://localhost:3000/api';
  static const String androidEmulator = 'http://10.0.2.2:3000/api';
  static const String iosSimulator = 'http://localhost:3000/api';
  static const String physicalDevice = 'http://192.168.1.33:3000/api'; // Your WiFi IP

}
