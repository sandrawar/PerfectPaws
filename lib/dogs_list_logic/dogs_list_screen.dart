import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:perfect_paws/menu_screen.dart';
import 'package:perfect_paws/offline_data_sync/networ_status.dart';
import 'package:perfect_paws/offline_data_sync/sync_act.dart';
import 'package:perfect_paws/offline_data_sync/sync_service.dart';
import '../volunteer_features/add_dog_form.dart';
import 'dog_class.dart';
import 'dog_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:perfect_paws/dogs_list_logic/dog_detail_card.dart';

class DogsListScreen extends StatefulWidget {
  const DogsListScreen({super.key});

  @override
  DogsListScreenState createState() => DogsListScreenState();
}

class DogsListScreenState extends State<DogsListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late User _currentUser;
  late CollectionReference _savedDogsCollection;

  bool _showOnlySaved = false;
  bool _isSortedBySaves = false;
  Box<Dog>? _savedDogsBox;
  Box<SyncAction>? _syncActionBox;

  Future<void> _openBox() async {
    //Hive.deleteFromDisk();
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
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  void toggle() => animationController.isDismissed
      ? animationController.forward()
      : animationController.reverse();

  final double maxSlide = 225.0;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    var myChild = Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(197, 174, 174, 1),
        automaticallyImplyLeading: false,
        leading: IconButton(
          alignment: Alignment.topLeft,
          icon: const Icon(
            Icons.menu,
            color: Colors.white,
          ),
          onPressed: () {
            toggle();
          },
        ),
        title: Text(
          localizations!.dogs,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showOnlySaved ? Icons.list : Icons.star,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showOnlySaved = !_showOnlySaved;
              });
            },
          ),
          IconButton(
            icon: Icon(
              _isSortedBySaves ? Icons.sort_by_alpha : Icons.sort,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isSortedBySaves = !_isSortedBySaves;
              });
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
                  icon: const Icon(
                    Icons.pets,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    context.go('/volunteer-dogs');
                  },
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
      backgroundColor: const Color.fromRGBO(188, 104, 104, 1),
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
              final dogs = _showOnlySaved ? box.values.toList() : [];

              if (!_showOnlySaved) {
                return FutureBuilder<List<Dog>>(
                  future: _getDogsFromFirebase(),
                  builder: (context, firebaseSnapshot) {
                    if (firebaseSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (firebaseSnapshot.hasError) {
                      return Center(
                          child: Text(
                              'Błąd pobierania psów: ${firebaseSnapshot.error}'));
                    }

                    final firebaseDogs = firebaseSnapshot.data ?? [];
                    dogs.addAll(firebaseDogs);

                    if (dogs.isEmpty) {
                      return Center(
                          child: Text(
                        localizations.emptyDogsList,
                        style: const TextStyle(color: Colors.white),
                      ));
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
                                onTap: () => DogDetailsCard.showDogDetails(
                                    dog, context, _toggleSaved),
                                child: DogCard(
                                    dog: dog,
                                    onFavoriteToggle: () {
                                      _toggleSaved(dog);
                                    },
                                    isFavorite: dog.isSaved),
                              );
                            },
                            separatorBuilder: (context, _) =>
                                const SizedBox(height: 16),
                          ),
                        ),
                      ],
                    );
                  },
                );
              }

              if (dogs.isEmpty) {
                return Center(child: Text(localizations.emptySavedDogsList));
              } else {
                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsetsDirectional.all(16),
                      sliver: SliverList.separated(
                        itemCount: dogs.length,
                        itemBuilder: (context, index) {
                          final dog = dogs[index];
                          return GestureDetector(
                            onTap: () => DogDetailsCard.showDogDetails(
                                dog, context, _toggleSaved),
                            child: DogCard(
                                dog: dog,
                                onFavoriteToggle: () {
                                  _toggleSaved(dog);
                                },
                                isFavorite: true),
                          );
                        },
                        separatorBuilder: (context, _) =>
                            const SizedBox(height: 16),
                      ),
                    ),
                  ],
                );
              }
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
                ).then((result) {
                  if (result == true) {
                    setState(() {});
                  }
                });
              },
              child: const Icon(Icons.add),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
    var myDrawer = MenuScreen();

    return MenuScreen.animatedMenu(
        myChild, myDrawer, maxSlide, toggle, animationController);
  }

  Future<List<Dog>> _getDogsFromFirebase() async {
    final dogsQuery = FirebaseFirestore.instance
        .collection('dogs')
        .orderBy('numberOfSaves', descending: !_isSortedBySaves);

    final querySnapshot = await dogsQuery.get();
    final dogs = querySnapshot.docs.map((doc) {
      return Dog.fromMap(doc.data(), id: doc.id);
    }).toList();
    for (var dog in dogs) {
      dog.isSaved = _savedDogsBox?.containsKey(dog.id) ?? false;
    }
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

  Future<void> _toggleSaved(Dog dog) async {
    if (dog.id.isEmpty) {
      return;
    }

    FirebaseFirestore.instance.collection('dogs').doc(dog.id);
    final savedDogRef = _savedDogsCollection.doc(dog.id);

    try {
      final isAlreadySavedLocal = _savedDogsBox?.containsKey(dog.id) ?? false;
      if (isAlreadySavedLocal) {
        await _savedDogsBox?.delete(dog.id);
      } else {
        await _savedDogsBox?.put(dog.id, dog);
        if (mounted) {
          _showSaveAnimation(context);
        }
      }

      NetworkStatusService networkStatusService = NetworkStatusService();
      if (await networkStatusService.isOnline) {
        final isAlreadySaved =
            await savedDogRef.get().then((doc) => doc.exists);

        final dogRef =
            FirebaseFirestore.instance.collection('dogs').doc(dog.id);

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Błąd przy zapisywaniu psa: $e")));
      }
    }
    setState(() {
      dog.isSaved = !dog.isSaved;
    });
  }

  void _showSaveAnimation(BuildContext context) {
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
                if (context.mounted && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              });
            },
          ),
        );
      },
    );
  }
}
