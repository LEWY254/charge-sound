import 'package:flutter/foundation.dart';

class MarketplaceAnalyticsService {
  const MarketplaceAnalyticsService._();

  static void track(
    String name, {
    Map<String, Object?> payload = const {},
  }) {
    debugPrint('[marketplace] $name $payload');
  }
}
