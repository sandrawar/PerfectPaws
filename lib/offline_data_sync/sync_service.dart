import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:perfect_paws/dogs_list_logic/dog_class.dart';
import 'package:perfect_paws/main.dart';
import 'package:perfect_paws/offline_data_sync/networ_status.dart';
import 'package:perfect_paws/offline_data_sync/sync_act.dart';

class SyncService {
  final Box<SyncAction> _syncActionBox;
  //final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User _currentUser;

  final errorNotifier = ErrorNotifier();
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
              _saveDogToFirebase(action.dogId);
            } else if (action.actionType == 'delete') {
              _deleteDogFromFirebase(action.dogId, index);
            }
            _syncActionBox.delete(key);
          } catch (e) {
            errorNotifier.setError(
                'An error occurred while processing the action. Please try again later.');
          }
        }
      }
    }
  }

  Future<void> _saveDogToFirebase(String dogId) async {
    CollectionReference savedDogsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid)
        .collection('saved_dogs');
    final savedDogRef = savedDogsCollection.doc(dogId);
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
        return;
      }

      CollectionReference savedDogsCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .collection('saved_dogs');
      final savedDogRef = savedDogsCollection.doc(dogId);

      final savedDogSnapshot = await savedDogRef.get();
      if (!savedDogSnapshot.exists) {
        return;
      }

      await savedDogRef.delete();

      await dogRef.update({
        'isSaved': false,
        'numberOfSaves': FieldValue.increment(-1),
      });
    } catch (e) {
      errorNotifier.setError(
          'An error occurred while processing the action. Please try again later.');
    }
  }
}
