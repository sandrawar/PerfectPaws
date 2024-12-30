import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:perfect_paws/message_list_screen.dart';
import 'add_dog_form.dart';
import 'dog_class.dart';
import 'dog_card.dart';
import 'package:flutter/foundation.dart';
import 'volunteer_dog_list_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser!;
    _savedDogsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid)
        .collection('saved_dogs');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dogs'),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _getDogQuery(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                  _showOnlySaved ? 'Brak zapisanych psów.' : 'Brak psów w bazie.'),
            );
          }

          final dogs = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Dog.fromMap(data, id: doc.id);
          }).toList();

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsetsDirectional.all(16),
                sliver: SliverList.separated(
                  itemCount: dogs.length,
                  itemBuilder: (context, index) {
                    final dog = dogs[index];
                    return FutureBuilder<bool>(
                      future: _isDogSaved(dog),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('Błąd: ${snapshot.error}'));
                        }

                        final isSaved = snapshot.data ?? false;
                        dog.isSaved = isSaved;

                        return GestureDetector(
                          onTap: () => _showDogDetails(dog), 
                          child: DogCard(
                            dog: dog,
                            onFavoriteToggle: () {
                              _toggleSaved(dog);
                            },
                          ),
                        );
                      },
                    );
                  },
                  separatorBuilder: (context, _) => const SizedBox(height: 16),
                ),
              ),
            ],
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

  Future<bool> _isDogSaved(Dog dog) async {
    final savedDogDoc = await _savedDogsCollection.doc(dog.id).get();
    return savedDogDoc.exists;
  }

  void _toggleSaved(Dog dog) async {
    if (dog.id.isEmpty) {
      print("Błąd: Dog ID is empty. Cannot toggle favorite.");
      return;
    }

    final dogRef = FirebaseFirestore.instance.collection('dogs').doc(dog.id);
    final savedDogRef = _savedDogsCollection.doc(dog.id); 

    try {
      final isAlreadySaved = await savedDogRef.get().then((doc) => doc.exists);

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
        _showSaveAnimation(context);
      }

      setState(() {
        dog.isSaved = !dog.isSaved;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Błąd przy zapisywaniu psa: $e")));
    }
  }

  void _showSaveAnimation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: kIsWeb
            ? Lottie.asset(
                'success.json',
                repeat: false,
                onLoaded: (composition) {
                  Future.delayed(composition.duration, () {
                    Navigator.of(context).pop();
                  });
                },
              )
            : Lottie.asset(
                'assets/success.json',
                repeat: false,
                onLoaded: (composition) {
                  Future.delayed(composition.duration, () {
                    Navigator.of(context).pop();
                  });
                },
              ),
      ),
      barrierDismissible: false,
    );
  }

  Stream<QuerySnapshot<Object?>> _getDogQuery() {
    if (_showOnlySaved) {
      return _savedDogsCollection.snapshots(); 
    } else {
      return FirebaseFirestore.instance
          .collection('dogs')
          .orderBy('numberOfSaves', descending: !_isSortedBySaves)
          .snapshots();
    }
  }

  Future<bool> _isUserVolunteer() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid)
        .get();
    final data = userDoc.data();
    return data != null && data['isVolunteer'] == true;
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

                FutureBuilder<bool>(
                  future: _isUserVolunteer(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink(); 
                    }

                    if (snapshot.data == true) {
                      return ElevatedButton(
                        onPressed: () {
                          context.go(
                            '/dog-details/${dog.id}',
                            extra: dog,
                          );
                        },
                        child: const Text('Edytuj'),
                      );
                    }

                    return const SizedBox.shrink(); 
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
}
