import 'package:flutter/material.dart';

// ============================================================
// ADMIN
// ============================================================

import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/admin_users_page.dart';
import '../../features/admin/presentation/pages/admin_students_page.dart';

// ============================================================
// ACADEMY
// ============================================================

import '../../features/academy/presentation/pages/academy_selection_page.dart';
import '../../features/academy/presentation/pages/institution_selection_page.dart';
import '../../features/academy/presentation/pages/access_pending_page.dart';

// ============================================================
// AUTH
// ============================================================

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';

// ============================================================
// HOME
// ============================================================

import '../../features/home/presentation/pages/home_page.dart';

// ============================================================
// GENERAL ONBOARDING
// ============================================================

import '../../features/onboarding/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/welcome_page.dart';

// ============================================================
// INSTITUTION ADMIN
// ============================================================

import '../../features/institution_admin/presentation/pages/institution_dashboard_page.dart';
import '../../features/institution_admin/presentation/pages/institution_classes_page.dart';
import '../../features/institution_admin/presentation/pages/institution_appearance_page.dart';

// ============================================================
// INSTITUTION ONBOARDING
// ============================================================

import '../../features/institution_onboarding/presentation/pages/institution_onboarding_flow_page.dart';
// ============================================================
// COSMIC / FLAME TEST
// ============================================================

import '../../cosmic/naos_cosmic_test_page.dart';

class AppRouter {
  // ==========================================================
  // GENERAL
  // ==========================================================

  static const String splash = '/';

  static const String welcome = '/welcome';

  static const String academy = '/academy';

  static const String login = '/login';

  static const String register = '/register';

  static const String home = '/home';

  static const String institution = '/institution';

  static const String accessPending = '/access-pending';

  // ==========================================================
  // SUPER ADMIN
  // ==========================================================

  static const String admin = '/admin';

  static const String adminUsers = '/admin/users';

  static const String adminStudents = '/admin/students';

  // ==========================================================
  // INSTITUTION ADMIN
  // ==========================================================

  static const String institutionAdmin = '/institution-admin';

  static const String institutionAdminClasses = '/institution-admin/classes';

  static const String institutionAdminAppearance =
      '/institution-admin/appearance';

  // ==========================================================
  // INSTITUTION ONBOARDING
  // ==========================================================

  static const String institutionOnboardingWelcome = '/institution-onboarding';

  // ==========================================================
  // COSMIC / FLAME TEST
  // ==========================================================

  static const String cosmicTest = '/cosmic-test';

  // ==========================================================
  // ROUTES
  // ==========================================================

  static final Map<String, WidgetBuilder> routes = {
    // ----------------------------------------------------------
    // GENERAL ONBOARDING
    // ----------------------------------------------------------
    splash: (context) => const SplashPage(),

    welcome: (context) => const WelcomePage(),

    // ----------------------------------------------------------
    // ACADEMY
    // ----------------------------------------------------------
    academy: (context) => const AcademySelectionPage(),

    // ----------------------------------------------------------
    // AUTHENTICATION
    // ----------------------------------------------------------
    login: (context) => const LoginPage(),

    register: (context) => const RegisterPage(),

    // ----------------------------------------------------------
    // STUDENT / GENERAL HOME
    // ----------------------------------------------------------
    home: (context) => const HomePage(),

    // ----------------------------------------------------------
    // INSTITUTION SELECTION
    // ----------------------------------------------------------
    institution: (context) => const InstitutionSelectionPage(),

    // ----------------------------------------------------------
    // SUPER ADMIN
    // ----------------------------------------------------------
    admin: (context) => const AdminDashboardPage(),

    adminUsers: (context) => const AdminUsersPage(),

    adminStudents: (context) => const AdminStudentsPage(),

    // ----------------------------------------------------------
    // INSTITUTION ADMIN
    // ----------------------------------------------------------
    institutionAdmin: (context) => const InstitutionDashboardPage(),

    institutionAdminClasses: (context) => const InstitutionClassesPage(),

    institutionAdminAppearance: (context) => const InstitutionAppearancePage(),

    // ----------------------------------------------------------
    // INSTITUTION ONBOARDING
    // ----------------------------------------------------------
    institutionOnboardingWelcome: (context) =>
        const InstitutionOnboardingFlowPage(),

    // ----------------------------------------------------------
    // OTHER
    // ----------------------------------------------------------
    accessPending: (context) => const AccessPendingPage(),

    // ----------------------------------------------------------
    // COSMIC / FLAME TEST
    // ----------------------------------------------------------
    cosmicTest: (context) => const NaosCosmicTestPage(),
  };
}
