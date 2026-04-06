import 'package:flutter/foundation.dart';

/// Placeholder for SMS / WhatsApp integration when attendance is saved.
void sendParentNotification({
  required String title,
  required String body,
  Map<String, String>? meta,
}) {
  debugPrint(
    '[sendParentNotification] $title — $body ${meta ?? {}}',
  );
}
