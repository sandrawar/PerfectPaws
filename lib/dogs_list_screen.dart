import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:perfect_paws/message_list_screen.dart';
import 'package:perfect_paws/networ_status.dart';
import 'package:perfect_paws/settings_screen.dart';
import 'package:perfect_paws/sync_act.dart';
import 'package:perfect_paws/sync_service.dart';
import 'add_dog_form.dart';
import 'dog_class.dart';
import 'dog_card.dart';
import 'package:flutter/foundation.dart';
import 'volunteer_dog_list_screen.dart';
import 'networ_status.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'settings_screen.dart';

class DogsListScreen extends StatefulWidget {
  const DogsListScreen({super.key});

  @override
  _DogsListScreenState createState() => _DogsListScreenState();
}

class _DogsListScreenState extends State<DogsListScreen> {
  late User _currentUser;
  late CollectionReference _savedDogsCollection;

  bool _showOnlySaved = false;
  bool _isSortedBySaves = false;
  Box<Dog>? _savedDogsBox;
  Box<SyncAction>? _syncActionBox;

  Future<void> _openBox() async {
    _savedDogsBox = await Hive.openBox<Dog>('saved_dogs');
    //_savedDogsBox?.clear();
  }

  Future<void> _initializeSyncService() async {
    _syncActionBox = await Hive.openBox<SyncAction>('sync_actions');
    final syncService = SyncService(_syncActionBox!);
    await syncService.syncOfflineChanges();
  }

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser!;
    _savedDogsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid)
        .collection('saved_dogs');

    _openBox();
    _initializeSyncService();
  }

  @override
  Widget build(BuildContext context) {

  final localizations = AppLocalizations.of(context);
  return Scaffold(
  appBar: AppBar(
  title: Text(localizations!.dogs),
    actions: [
      IconButton(
        icon: Icon(_showOnlySaved ? Icons.list : Icons.star),
        onPressed: () {
          setState(() {
            _showOnlySaved = !_showOnlySaved;
          });
        },
      ),
      IconButton(
        icon: Icon(
          _isSortedBySaves ? Icons.sort_by_alpha : Icons.sort,
        ),
        onPressed: () {
          setState(() {
            _isSortedBySaves = !_isSortedBySaves;
          });
        },
      ),
      IconButton(
        icon: const Icon(Icons.message),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MessagesListScreen(),
            ),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SettingsScreen(),
            ),
          );
        },
      ),
      FutureBuilder<bool>(
        future: _isUserVolunteer(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }

          if (snapshot.data == true) {
            return IconButton(
              icon: const Icon(Icons.pets),
              onPressed: () {
                context.go('/volunteer-dogs');
              },
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
      IconButton(
        icon: const Icon(Icons.exit_to_app),
        onPressed: _logout,
      ),
    ],
  ),
  body: FutureBuilder<void>(
    future: Future.wait([_openBox(), _initializeSyncService()]),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(child: Text('Błąd inicjalizacji: ${snapshot.error}'));
      }

      return ValueListenableBuilder(
        valueListenable: _savedDogsBox!.listenable(),
        builder: (context, Box<Dog> box, _) {
          final dogs = _showOnlySaved
              ? box.values.toList() // When showing saved dogs, use HiveBox
              : []; // Initially empty list for Firebase dogs

          // If we're not showing only saved dogs, fetch them from Firebase
          if (!_showOnlySaved) {
            return FutureBuilder<List<Dog>>(
              future: _getDogsFromFirebase(),
              builder: (context, firebaseSnapshot) {
                if (firebaseSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (firebaseSnapshot.hasError) {
                  return Center(child: Text('Błąd pobierania psów: ${firebaseSnapshot.error}'));
                }

                // Use the fetched dogs from Firebase
                final firebaseDogs = firebaseSnapshot.data ?? [];
                dogs.addAll(firebaseDogs); // Combine saved and Firebase dogs
                if (dogs.isEmpty) {
                  return const Center(child: Text('Brak psów.'));
                }

                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsetsDirectional.all(16),
                      sliver: SliverList.separated(
                        itemCount: dogs.length,
                        itemBuilder: (context, index) {
                          final dog = dogs[index];
                          return GestureDetector(
                            onTap: () => _showDogDetails(dog),
                            child: DogCard(
                              dog: dog,
                              onFavoriteToggle: () {
                                _toggleSaved(dog);
                              },                     
                        isFavorite: dog.isSaved
                            ),
                          );
                        },
                        separatorBuilder: (context, _) => const SizedBox(height: 16),
                      ),
                    ),
                  ],
                );
              },
            );
          }

          // If showing only saved dogs, handle HiveBox
          if (dogs.isEmpty) {
            return const Center(child: Text('Brak zapisanych psów.'));
          }

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsetsDirectional.all(16),
                sliver: SliverList.separated(
                  itemCount: dogs.length,
                  itemBuilder: (context, index) {
                    final dog = dogs[index];
                    return GestureDetector(
                      onTap: () => _showDogDetails(dog),
                      child: DogCard(
                        dog: dog,
                        onFavoriteToggle: () {
                          _toggleSaved(dog);
                        },
                        isFavorite: dog.isSaved
                      ),
                    );
                  },
                  separatorBuilder: (context, _) => const SizedBox(height: 16),
                ),
              ),
            ],
          );
        },
      );
    },
  ),
  floatingActionButton: FutureBuilder<bool>(
    future: _isUserVolunteer(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const SizedBox.shrink();
      }

      if (snapshot.data == true) {
        return FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return const AddDogForm();
              },
            );
          },
          child: const Icon(Icons.add),
        );
      } else {
        return const SizedBox.shrink();
      }
    },
  ),
);
  }

  Widget _buildDogList(List<Dog> dogs) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsetsDirectional.all(16),
          sliver: SliverList.separated(
            itemCount: dogs.length,
            itemBuilder: (context, index) {
              final dog = dogs[index];
              return GestureDetector(
                onTap: () => _showDogDetails(dog),
                child: DogCard(
                  dog: dog,
                  onFavoriteToggle: () {
                    _toggleSaved(dog);
                  },
                  isFavorite: dog.isSaved,
                ),
              );
            },
            separatorBuilder: (context, _) => const SizedBox(height: 16),
          ),
        ),
      ],
    );
  }

  Future<List<Dog>> _getDogsFromFirebase() async {
    final dogsQuery = FirebaseFirestore.instance
        .collection('dogs')
        .orderBy('numberOfSaves', descending: !_isSortedBySaves);

    final querySnapshot = await dogsQuery.get();
    final dogs = querySnapshot.docs.map((doc) {
      return Dog.fromMap(doc.data(), id: doc.id);
    }).toList();

    return dogs;
  }

  Future<bool> _isUserVolunteer() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid)
        .get();
    final data = userDoc.data();
    return data != null && data['isVolunteer'] == true;
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      context.go('/login');
    } catch (e) {
      print("Błąd przy wylogowywaniu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błąd przy wylogowywaniu: $e")),
      );
    }
  }

  Future<void> _toggleSaved(Dog dog) async {
    if (dog.id.isEmpty) {
      print("Błąd: Dog ID is empty. Cannot toggle favorite.");
      return;
    }

    final dogRef = FirebaseFirestore.instance.collection('dogs').doc(dog.id);
    final savedDogRef = _savedDogsCollection.doc(dog.id);

    try {
      final isAlreadySavedLocal = _savedDogsBox?.containsKey(dog.id) ?? false;
      if (isAlreadySavedLocal) {
        await _savedDogsBox?.delete(dog.id);
      } else {
        await _savedDogsBox?.put(dog.id, dog);    
        _showSaveAnimation(context);
      }

  NetworkStatusService networkStatusService = NetworkStatusService(); 
      if(await networkStatusService.isOnline) {
        final isAlreadySaved = await savedDogRef.get().then((doc) => doc.exists);
        
        final dogRef = FirebaseFirestore.instance.collection('dogs').doc(dog.id);

        if (isAlreadySaved) {
          await savedDogRef.delete();
          await dogRef.update({
            'isSaved': false,
            'numberOfSaves': FieldValue.increment(-1),
          });
        } else {
          await savedDogRef.set(dog.toMap());
          await dogRef.update({
            'isSaved': true,
            'numberOfSaves': FieldValue.increment(1),
          });
        }
      } else {
        final syncAction = SyncAction(
        actionType: isAlreadySavedLocal ? 'delete' : 'save',
        dogId: dog.id,
        timestamp: DateTime.now(),
      );
      await Hive.box<SyncAction>('sync_actions').add(syncAction);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Błąd przy zapisywaniu psa: $e")));
    }
    setState(() {
        dog.isSaved = !dog.isSaved;
      });
  }

void _showSaveAnimation(BuildContext conext) {
  showDialog(
    context: context,
    barrierDismissible: false, 
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Lottie.asset(
          'assets/success.json', 
          repeat: false, 
          onLoaded: (composition) {
            Future.delayed(composition.duration, () {
              Navigator.of(context).pop();
            });
          },
        ),
      );
    },
  );
}


  void _showDogDetails(Dog dog) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dog.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (dog.imageUrl.isNotEmpty)
                    Image.network(
                      dog.imageUrl,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Imię: ${dog.name}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    'Wiek: ${dog.age}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Opis: ${dog.description}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lokalizacja: ${dog.location}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
