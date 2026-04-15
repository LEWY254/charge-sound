import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'services/supabase_service.dart';
import 'utils/startup_env_guard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  StartupEnvGuard.enforce(strict: kReleaseMode);
  await SupabaseService.initialize(strict: kReleaseMode);
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.tracesSampleRate = 0.2;
    },
    appRunner: () =>
        runApp(const ProviderScope(child: SoundTriggerApp())),
  );
}
