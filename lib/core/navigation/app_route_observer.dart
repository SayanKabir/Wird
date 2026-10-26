import 'package:flutter/widgets.dart';

/// Tells screens when another route covers them or uncovers them again, so
/// something only meant for the visible screen (the home sky's rain) can
/// stop and start. Registered on the app's navigator in main.dart.
final RouteObserver<ModalRoute<void>> appRouteObserver = RouteObserver<ModalRoute<void>>();
