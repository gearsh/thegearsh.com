// Compatibility shim for older imports. The canonical router lives in `lib/routes/app_router.dart`.
// Prefer importing `package:gearsh_app/routes/app_router.dart` and using `router`.

export 'routes/app_router.dart' show router;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'routes/app_router.dart' as routes;

/// A simple provider wrapper that returns the canonical `router` instance.
final goRouterProvider = Provider<GoRouter>((ref) => routes.router);
