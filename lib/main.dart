import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/di/app_dependencies.dart';
import 'core/utils/app_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final AppConfig config = AppConfig.fromEnvironment();
  AppConfigScope.override(config);
  AppLogger.debug(
    'Starting in ${config.environment.name} against ${config.apiBaseUrl} '
    '(mock API: ${config.useMockApi})',
  );

  runApp(MathTutorApp(dependencies: AppDependencies.create(config: config)));
}
