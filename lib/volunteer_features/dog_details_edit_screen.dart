import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:perfect_paws/dogs_list_logic/dog_class.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:perfect_paws/volunteer_features/item_fader.dart';

class DogDetailsScreen extends StatefulWidget {
  final Dog dog;

  const DogDetailsScreen({required this.dog, super.key});

  @override
  DogDetailsScreenState createState() => DogDetailsScreenState();
}

class DogDetailsScreenState extends State<DogDetailsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late DateTime _selectedBirthDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.dog.name);
    _descriptionController =
        TextEditingController(text: widget.dog.description);
    _locationController = TextEditingController(text: widget.dog.location);
    _selectedBirthDate = widget.dog.birthDate.toDate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = pickedDate;
      });
    }
  }

  void _updateDogData() async {
    final localizations = AppLocalizations.of(context);

    final updatedDog = widget.dog.copyWith(
      name: _nameController.text,
      birthDate: Timestamp.fromDate(_selectedBirthDate),
      description: _descriptionController.text,
      location: _locationController.text,
    );

    try {
      await FirebaseFirestore.instance
          .collection('dogs')
          .doc(widget.dog.id)
          .update(updatedDog.toMap());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations!.dogsDataUpdated)),
        );
        context.go('/volunteer-dogs');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations!.dogsDataUpdateError)),
        );
      }
    }
  }

  Future<void> _deleteDog() async {
    final localizations = AppLocalizations.of(context);
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations!.deleteDogQuestion),
        content: Text(localizations.deleteDogPermanent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(localizations.deleteDog),
          ),
        ],
      ),
    );

    if (confirmation == true) {
      try {
        await FirebaseFirestore.instance
            .collection('dogs')
            .doc(widget.dog.id)
            .delete();

        await _deleteFromSavedDogs();

        await _deleteDogFromHive();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations!.dogDeleted)),
          );
          context.go('/volunteer-dogs');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations!.error)),
          );
        }
      }
    }
  }

  Future<void> _deleteFromSavedDogs() async {
    final localizations = AppLocalizations.of(context)!;
    final usersIds = await _getAllUserIds();
    for (var userId in usersIds) {
      final savedDogsSnapshots = await FirebaseFirestore.instance
          .collectionGroup('saved_dogs')
          .where(FieldPath.documentId,
              isEqualTo: 'users/$userId/saved_dogs/${widget.dog.id}')
          .get();

      for (var doc in savedDogsSnapshots.docs) {
        try {
          await doc.reference.delete();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(localizations.error)));
          }
        }
      }
    }
  }

  Future<void> _deleteDogFromHive() async {
    final localizations = AppLocalizations.of(context)!;
    try {
      final userIds = await _getAllUserIds();

      for (var userId in userIds) {
        final box = await Hive.openBox<Dog>('saved_dogs_$userId');

        if (box.containsKey(widget.dog.id)) {
          await box.delete(widget.dog.id);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(localizations.error)));
      }
    }
  }

  Future<List<String>> _getAllUserIds() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    return querySnapshot.docs.map((doc) => doc.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dog.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/volunteer-dogs');
          },
        ),
      ),
      backgroundColor: const Color.fromRGBO(197, 174, 174, 2),
      body: MyPage(
        elements: [
          if (widget.dog.imageUrl.isNotEmpty)
            ClipOval(
                child: Image.network(widget.dog.imageUrl,
                    height: 200, width: 200, fit: BoxFit.cover)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: localizations!.dogsName,
              labelStyle: const TextStyle(color: Colors.white),
              hintStyle: TextStyle(color: Colors.white.withAlpha(150)),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _selectBirthDate(context),
            child: AbsorbPointer(
              child: TextField(
                controller: TextEditingController(
                    text: '${_selectedBirthDate.toLocal()}'.split(' ')[0]),
                decoration: InputDecoration(
                  labelText: localizations.dogsAge,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: localizations.dogsDescription,
              labelStyle: const TextStyle(color: Colors.white),
            ),
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: localizations.dogsLocation,
              labelStyle: const TextStyle(color: Colors.white),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _updateDogData,
            child: Text(localizations.saveChanges),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _deleteDog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(localizations.deleteDog),
          ),
        ],
        onNext: _updateDogData,
      ),
    );
  }
}
