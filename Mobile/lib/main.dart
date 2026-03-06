import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:municipalgo/pages/authentification.dart';
import 'package:municipalgo/services/roleProvider.dart';
import 'package:municipalgo/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'generated/l10n.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:municipalgo/http/lib_http.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const supabaseUrl = '';
const supabaseKey = '';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseBgHandler);

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

  final roleProvider = RoleProvider();
  await roleProvider.loadUserFromStorage();

  if (roleProvider.isLoggedIn) {
    if (isTokenExpired(roleProvider.token)) {
      await roleProvider.logout();
    } else {
      restoreAuthFromProvider(roleProvider);
      await FirebaseService.initialize();
    }
  }

  AuthStore.onSessionExpired = () async {
    await roleProvider.logout();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthentificationPage()),
      (route) => false,
    );
  };

  runApp(
    ChangeNotifierProvider.value(
      value: roleProvider,
      child: const MyApp(),
    ),
  );
}
Future<void> _firebaseBgHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'MunicipaliGo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
      ),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: const AuthentificationPage(),
    );
  }
}
