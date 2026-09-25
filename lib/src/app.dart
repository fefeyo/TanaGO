import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/presentation/auth_controller.dart';
import 'features/household/presentation/household_controller.dart';
import 'features/household/presentation/household_page.dart';
import 'features/household/presentation/household_setup_page.dart';
import 'features/map_editor/presentation/map_editor_page.dart';
import 'features/shopping_list/presentation/shopping_list_page.dart';
import 'features/shopping_map/presentation/shopping_map_page.dart';
import 'features/stores/presentation/store_list_page.dart';
import 'features/product_categories/presentation/categories_page.dart';
import 'features/shopping_trip/presentation/shopping_selection_page.dart';
import 'features/shopping_trip/presentation/shopping_completion_page.dart';

final _routerProvider = Provider.autoDispose<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      ShellRoute(
        // Keep setup/loading/error pages inside the root Navigator so text
        // selection, menus and dialogs always have an Overlay ancestor.
        builder: (context, state, child) => _HouseholdGate(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const ShoppingListPage(),
          ),
          GoRoute(
            path: '/household',
            builder: (context, state) => const HouseholdPage(),
          ),
          GoRoute(
            path: '/stores',
            builder: (context, state) => StoreListPage(
              shopping: state.uri.queryParameters['shopping'] == 'true',
            ),
          ),
          GoRoute(
            path: '/categories',
            builder: (context, state) => const CategoriesPage(),
          ),
          GoRoute(
            path: '/stores/:storeId/select',
            builder: (context, state) => ShoppingSelectionPage(
              storeId: state.pathParameters['storeId']!,
            ),
          ),
          GoRoute(
            path: '/stores/:storeId/complete',
            builder: (context, state) => ShoppingCompletionPage(
              storeId: state.pathParameters['storeId']!,
            ),
          ),
          GoRoute(
            path: '/stores/:storeId/map',
            builder: (context, state) => ShoppingMapPage(
              storeId: state.pathParameters['storeId']!,
            ),
          ),
          GoRoute(
            path: '/stores/:storeId/map/edit',
            builder: (context, state) => MapEditorPage(
              storeId: state.pathParameters['storeId']!,
            ),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class TanaGoApp extends ConsumerWidget {
  const TanaGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'TanaGO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
        ),
        useMaterial3: true,
      ),
      routerConfig: ref.watch(_routerProvider),
    );
  }
}

class _HouseholdGate extends ConsumerWidget {
  const _HouseholdGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(householdProvider).when(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('世帯情報を読み込めませんでした: $error'),
                  FilledButton(
                    onPressed: () {
                      ref.invalidate(authBootstrapProvider);
                      ref.invalidate(authUserProvider);
                      ref.invalidate(householdProvider);
                    },
                    child: const Text('再試行'),
                  ),
                ],
              ),
            ),
          ),
          data: (value) => value == null ? const HouseholdSetupPage() : child,
        );
  }
}
