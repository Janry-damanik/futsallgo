import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/providers/admin_settings_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/premium_theme.dart';
import 'core/theme/theme_mode_controller.dart';

class FutsalGoApp extends ConsumerStatefulWidget {
  const FutsalGoApp({super.key});

  @override
  ConsumerState<FutsalGoApp> createState() => _FutsalGoAppState();
}

class _FutsalGoAppState extends ConsumerState<FutsalGoApp>
    with WidgetsBindingObserver {
  static const _settingsRefreshInterval = Duration(seconds: 30);

  Timer? _settingsRefreshTimer;
  bool _isRefreshingSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settingsRefreshTimer = Timer.periodic(_settingsRefreshInterval, (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(_refreshSettings());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshSettings());
    }
  }

  Future<void> _refreshSettings() async {
    if (_isRefreshingSettings) return;
    _isRefreshingSettings = true;
    try {
      await ref.read(adminSettingsProvider.notifier).reload();
    } finally {
      _isRefreshingSettings = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settingsRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: PremiumTheme.light,
      darkTheme: PremiumTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return Material(
          child: Column(
            children: [Expanded(child: child ?? const SizedBox.shrink())],
          ),
        );
      },
    );
  }
}
