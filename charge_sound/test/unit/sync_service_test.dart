import 'package:flutter_test/flutter_test.dart';
import 'package:sound_trigger/services/sync_service.dart';

void main() {
  test('sync service instantiates', () {
    const service = SyncService();
    expect(service, isA<SyncService>());
  });
}
