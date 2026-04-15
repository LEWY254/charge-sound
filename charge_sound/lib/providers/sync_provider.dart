import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return const SyncService();
});
