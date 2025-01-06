import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:perfect_paws/dog_class.dart';
import 'package:perfect_paws/dog_details_screen.dart';
import 'package:perfect_paws/firebase_options.dart';
import 'package:perfect_paws/networ_status.dart';
import 'package:perfect_paws/sync_act.dart';
import 'package:perfect_paws/sync_service.dart';
import 'package:perfect_paws/volunteer_dog_list_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dogs_list_screen.dart'; 
import 'login_screen.dart'; 
import 'register_screen.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
  }
  await Hive.initFlutter();
   Hive.registerAdapter(DogAdapter());
  Hive.registerAdapter(SyncActionAdapter());


  var syncActionBox = await Hive.openBox<SyncAction>('syncActions');
   
   var syncService = SyncService(Hive.box<SyncAction>('syncActions'));

  NetworkStatusService().connectivityStream.listen((result) async {
    if (result != ConnectivityResult.none) {
      await syncService.syncOfflineChanges();
    }
  });
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'Perfect Paws',
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

