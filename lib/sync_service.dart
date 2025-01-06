import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:perfect_paws/dog_class.dart';
import 'package:perfect_paws/networ_status.dart';
import 'package:perfect_paws/sync_act.dart';

class SyncService {
  final Box<SyncAction> _syncActionBox;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User _currentUser;

  SyncService(this._syncActionBox);

  Future<void> syncOfflineChanges() async {
    if (await NetworkStatusService().isOnline) {
      
    _currentUser = FirebaseAuth.instance.currentUser!;
      for (int index = 0; index < _syncActionBox.length; index++) {
        final key = _syncActionBox.keyAt(index); 
        final action = _syncActionBox.get(key); 
        
        if (action != null) {
          try {
            if (action.actionType == 'save') {
              await _saveDogToFirebase(action.dogId);
            } else if (action.actionType == 'delete') {
              await _deleteDogFromFirebase(action.dogId, index);
            }
            await _syncActionBox.delete(key); 
          } catch (e) {
            print('Błąd przy synchronizacji: $e');
          }
        }
      }
    }
  }

  
  

  Future<void> _saveDogToFirebase(String dogId) async {
      CollectionReference _savedDogsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid)
        .collection('saved_dogs');
  final savedDogRef = _savedDogsCollection.doc(dogId);
  final dogRef = FirebaseFirestore.instance.collection('dogs').doc(dogId);

  final savedDogSnapshot = await savedDogRef.get();
  final dogSnapshot = await dogRef.get();

  if (!savedDogSnapshot.exists && dogSnapshot.exists) {
    final dogData = dogSnapshot.data() as Map<String, dynamic>;

    await savedDogRef.set(Dog.fromMap(dogData)); 

    await dogRef.update({
      'isSaved': true,
      'numberOfSaves': FieldValue.increment(1), 
    });
  }
}


  Future<void> _deleteDogFromFirebase(String dogId, int index) async {
  try {
    final dogRef = FirebaseFirestore.instance.collection('dogs').doc(dogId);

    final dogSnapshot = await dogRef.get();
    if (!dogSnapshot.exists) {
      print('Błąd: Pies o ID $dogId nie istnieje w Firebase');
      return;
    }

    CollectionReference savedDogsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid)
        .collection('saved_dogs');
    final savedDogRef = savedDogsCollection.doc(dogId);

    final savedDogSnapshot = await savedDogRef.get();
    if (!savedDogSnapshot.exists) {
      print('Błąd: Pies o ID $dogId nie jest zapisany w Firebase');
      return;
    }

    await savedDogRef.delete();

    await dogRef.update({
      'isSaved': false,
      'numberOfSaves': FieldValue.increment(-1),
    });


    print('Pies o ID $dogId został pomyślnie usunięty z zapisanych psów. (index: $index)');
  } catch (e) {
    print('Błąd przy usuwaniu psa: $e');
  }
}

}
