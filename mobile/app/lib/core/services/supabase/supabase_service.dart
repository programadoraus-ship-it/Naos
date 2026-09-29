import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl =
      'https://llebztltvpzrnlaxrwba.supabase.co';

  static const String supabasePublishableKey =
      'sb_publishable_-SM1g3wmr0yJmzi0lnqPpQ_ElboRFkI';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        detectSessionInUri: true,
      ),
    );
  }

  static SupabaseClient get client =>
      Supabase.instance.client;

  /// Usuario actualmente autenticado.
  static User? get currentUser =>
      client.auth.currentUser;

  /// Sesión actualmente disponible.
  static Session? get currentSession =>
      client.auth.currentSession;

  /// Obtiene el perfil del usuario actualmente autenticado.
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = client.auth.currentUser;

    if (user == null) {
      return null;
    }

    final response = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return response;
  }

  /// Obtiene el rol actual del usuario.
  static Future<String?> getCurrentUserRole() async {
    final user = client.auth.currentUser;

    if (user == null) {
      return null;
    }

    final response = await client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return response['role'] as String?;
  }
}