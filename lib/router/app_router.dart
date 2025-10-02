import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/role_selector_screen.dart';
import '../screens/parent_home_screen.dart';
import '../screens/driver_home_screen.dart';
import '../screens/group_setup_screen.dart';
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

    // Driver home screen (pre-operation)
    GoRoute(
      path: '/driver-home',
      name: 'driver-home',
      builder: (context, state) {
        final Map<String, dynamic> params = state.extra as Map<String, dynamic>;
        return DriverHomeScreen(
          user: params['user'] as UserModel,
          group: params['group'] as GroupModel?,
        );
      },
    ),
  ],
);
