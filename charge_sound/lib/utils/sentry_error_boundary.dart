import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> captureAndRethrow(
  Object error,
  StackTrace stackTrace,
) async {
  await Sentry.captureException(error, stackTrace: stackTrace);
}
