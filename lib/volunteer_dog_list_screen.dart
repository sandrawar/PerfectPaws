import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dog_class.dart';
import 'add_dog_form.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class VolunteerDogsListScreen extends StatefulWidget {
  const VolunteerDogsListScreen({super.key});

  @override
  _VolunteerDogsListScreenState createState() =>
      _VolunteerDogsListScreenState();
}

class _VolunteerDogsListScreenState extends State<VolunteerDogsListScreen> {
  late User _currentUser;
  late Stream<QuerySnapshot> _dogsStream;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser!;
    _getDogsForVolunteer();
  }

  void _getDogsForVolunteer() {
    _dogsStream = FirebaseFirestore.instance
        .collection('dogs')
        .where('volunteer', isEqualTo: _currentUser.email)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    
  final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations!.myDogs),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/');
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dogsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('${localizations.error}: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text(localizations.noPosts));
          }

          final dogs = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Dog.fromMap(data, id: doc.id);
          }).toList();

          return ListView.builder(
            itemCount: dogs.length,
            itemBuilder: (context, index) {
              final dog = dogs[index];
              return ListTile(
                title: Text(dog.name),
                subtitle: Text('${localizations.numberOfSaves} ${dog.numberOfSaves}'),
                leading: dog.imageUrl.isNotEmpty
                    ? Image.network(dog.imageUrl, width: 50, height: 50)
                    : const Icon(Icons.pets),
                onTap: () {
                  context.go(
                    '/dog-details/${dog.id}',
                    extra: dog,
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return const AddDogForm();
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
