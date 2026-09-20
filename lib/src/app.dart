import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/map_editor/presentation/map_editor_page.dart';
import 'features/shopping_list/presentation/shopping_list_page.dart';
import 'features/shopping_map/presentation/shopping_map_page.dart';
import 'features/stores/presentation/store_list_page.dart';

class TanaGoApp extends StatelessWidget {
  const TanaGoApp({super.key});

  static final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const ShoppingListPage(),
      ),
      GoRoute(
        path: '/stores',
        builder: (context, state) => const StoreListPage(),
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
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TanaGO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
