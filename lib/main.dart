import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'language/locale_provider.dart';
import 'language/settings_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
  }
  
  //Hive.deleteFromDisk(); 
  await Hive.initFlutter();

  // Usuń wszystkie dane Hive
  //await Hive.deleteFromDisk();
   Hive.registerAdapter(DogAdapter());
  Hive.registerAdapter(SyncActionAdapter());


  var syncActionBox = await Hive.openBox<SyncAction>('syncActions');
   
   var syncService = SyncService(Hive.box<SyncAction>('syncActions'));

  NetworkStatusService().connectivityStream.listen((result) async {
    if (result != ConnectivityResult.none) {
      await syncService.syncOfflineChanges();
    }
  });

  //await Hive.deleteFromDisk(); // Usuwa wszystkie boxy i ich dane

  
  runApp(ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: const MyApp(),
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
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  errorPageBuilder: (context, state) => MaterialPage(
    child: Scaffold(
      body: Center(
        child: Text('Błąd: ${state.error}'),
      ),
    ),
  ),
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isOnLoginPage = state.matchedLocation == '/login' || state.matchedLocation == '/register';

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
    ),GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => SettingsScreen(),
    ),
    GoRoute(
      path: '/dog-details/:id',
      name: 'dogDetails',
      builder: (context, state) {
        final dogData = state.extra as Dog?;
        if (dogData == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Błąd')),
            body: const Center(child: Text('Nie znaleziono szczegółów psa')),
          );
        }
        return DogDetailsScreen(dog: dogData);
      },
    ),
  ],
);

