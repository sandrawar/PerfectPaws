import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:perfect_paws/dogs_list_logic/dog_class.dart';
import 'package:go_router/go_router.dart'; 
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; 

class DogDetailsScreen extends StatefulWidget {
  final Dog dog;

  const DogDetailsScreen({required this.dog, super.key});

  @override
  _DogDetailsScreenState createState() => _DogDetailsScreenState();
}

class _DogDetailsScreenState extends State<DogDetailsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.dog.name);
    _ageController = TextEditingController(text: widget.dog.age.toString());
    _descriptionController =
        TextEditingController(text: widget.dog.description);
    _locationController = TextEditingController(text: widget.dog.location);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _updateDogData() async {
    
  final localizations = AppLocalizations.of(context);
    final updatedDog = widget.dog.copyWith(
      name: _nameController.text,
      age: int.tryParse(_ageController.text) ?? widget.dog.age,
      description: _descriptionController.text,
      location: _locationController.text,
    );

    try {
      await FirebaseFirestore.instance
          .collection('dogs')
          .doc(widget.dog.id)
          .update(updatedDog.toMap());
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations!.dogsDataUpdated)),
      );

      context.go('/volunteer-dogs');  
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations!.dogsDataUpdateError)),
      );
    }
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.dog.imageUrl.isNotEmpty)
              Image.network(widget.dog.imageUrl, height: 200, fit: BoxFit.cover),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: localizations!.dogsName),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ageController,
              decoration: InputDecoration(labelText: localizations.dogsAge),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: localizations.dogsDescription),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(labelText: localizations.dogsLocation),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateDogData,
              child: Text(localizations.saveChanges),
            ),
          ],
        ),
      ),
    );
  }
}
