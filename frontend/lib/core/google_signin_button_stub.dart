import 'package:flutter/widgets.dart';

/// Non-web platforms don't support the rendered Google Identity Services
/// button; the login screen only shows this on web (see kIsWeb checks).
Widget renderButton() {
  throw StateError('renderButton() is only supported on web');
}
