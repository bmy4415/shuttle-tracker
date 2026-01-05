import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/role_selector_screen.dart';
import '../screens/parent_home_screen.dart';
import '../screens/driver_home_screen.dart';
import '../screens/driver_groups_screen.dart';
import '../screens/group_setup_screen.dart';
import '../screens/settings_screen.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';

/// App router configuration using go_router
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Role selector screen (initial screen)
    GoRoute(
      path: '/',
      name: 'role-selector',
      builder: (context, state) => const RoleSelectorScreen(),
    ),

    // Group setup screen
    GoRoute(
      path: '/group-setup',
      name: 'group-setup',
      builder: (context, state) {
        final user = state.extra as UserModel;
        return GroupSetupScreen(user: user);
      },
    ),

    // Parent home screen
    GoRoute(
      path: '/parent-home',
      name: 'parent-home',
      builder: (context, state) {
        final Map<String, dynamic> params = state.extra as Map<String, dynamic>;
        return ParentHomeScreen(
          user: params['user'] as UserModel,
          group: params['group'] as GroupModel?,
        );
      },
    ),

    // Driver groups list screen
    GoRoute(
      path: '/driver-groups',
      name: 'driver-groups',
      builder: (context, state) {
        return const DriverGroupsScreen();
      },
    ),

    // Driver home screen with group ID
    GoRoute(
      path: '/driver-home/:groupId',
      name: 'driver-home-group',
      builder: (context, state) {
        final groupId = state.pathParameters['groupId'];
        final user = state.extra as UserModel?;

        // If user is not passed, we need to get it from auth service
        // For now, create a placeholder that will be replaced in the screen
        if (user == null) {
          // This case shouldn't happen in normal flow
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('사용자 정보를 불러올 수 없습니다'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('처음으로'),
                  ),
                ],
              ),
            ),
          );
        }

        return DriverHomeScreen(
          user: user,
          groupId: groupId,
        );
      },
    ),

    // Legacy driver home screen (redirect to groups)
    GoRoute(
      path: '/driver-home',
      name: 'driver-home',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is Map<String, dynamic>) {
          final user = extra['user'] as UserModel?;
          final group = extra['group'] as GroupModel?;
          if (user != null && group != null) {
            return DriverHomeScreen(
              user: user,
              groupId: group.id,
            );
          }
        }
        // Redirect to driver groups if no params
        return const DriverGroupsScreen();
      },
    ),

    // Settings screen
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
