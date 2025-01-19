import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:perfect_paws/dogs_list_logic/dog_class.dart';
import 'package:perfect_paws/volunteer_features/dog_details_edit_screen.dart';
import 'package:perfect_paws/auth/firebase_options.dart';
import 'package:perfect_paws/offline_data_sync/networ_status.dart';
import 'package:perfect_paws/offline_data_sync/sync_act.dart';
import 'package:perfect_paws/offline_data_sync/sync_service.dart';
import 'package:perfect_paws/volunteer_features/volunteer_dog_list_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'dogs_list_logic/dogs_list_screen.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'language/locale_provider.dart';
import 'language/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final errorNotifier = ErrorNotifier();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    errorNotifier.setError(
        'An error occurred while processing the action. Please try again later.');
  }
  await Hive.initFlutter();
  Hive.registerAdapter(DogAdapter());
  Hive.registerAdapter(SyncActionAdapter());

  await Hive.openBox<SyncAction>('syncActions');

  var syncService = SyncService(Hive.box<SyncAction>('syncActions'));

  NetworkStatusService().connectivityStream.listen((result) async {
    if (result != ConnectivityResult.none) {
      await syncService.syncOfflineChanges();
    }
  });

  runApp(ChangeNotifierProvider(
    create: (_) => ErrorNotifier(),
    child: ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: const MyApp(),
    ),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    return MaterialApp.router(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          AppLocalizations.delegate
        ],
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('es', 'ES'),
          Locale('pl', 'PL'),
        ],
        routerConfig: _router,
        title: "Perfect Paws",
        locale: localeProvider.locale,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepOrange,
          ),
        ),
        builder: (context, child) {
          return Consumer<ErrorNotifier>(
            builder: (context, errorNotifier, child) {
              if (errorNotifier.errorMessage != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorNotifier.errorMessage!),
                      backgroundColor: Colors.red,
                    ),
                  );
                });
              }
              return child!;
            },
            child: child,
          );
        });
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  errorPageBuilder: (context, state) => MaterialPage(
    child: Scaffold(
      body: Center(
        child: Text('${AppLocalizations.of(context)!.errorMessage}; ${state.error}'),
      ),
    ),
  ),
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isOnLoginPage = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (!isLoggedIn && !isOnLoginPage) {
      return '/login';
    }

    if (isLoggedIn && isOnLoginPage) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const DogsListScreen(),
    ),
    GoRoute(
      path: '/volunteer-dogs',
      name: 'volunteerDogs',
      builder: (context, state) => const VolunteerDogsListScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/dog-details/:id',
      name: 'dogDetails',
      builder: (context, state) {
    final localizations = AppLocalizations.of(context)!;
        final dogData = state.extra as Dog?;
        if (dogData == null) {
          return Scaffold(
            appBar: AppBar(title: Text(localizations.errorMessage)),
            body: Center(child: Text(localizations.errorMessage)),
          );
        }
        return DogDetailsScreen(dog: dogData);
      },
    ),
  ],
);

class ErrorNotifier extends ChangeNotifier {
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
}
