import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    _selectedBirthDate =
        widget.dog.birthDate.toDate(); 
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
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () =>
                _selectBirthDate(context), 
            child: AbsorbPointer(
              child: TextField(
                controller: TextEditingController(
                    text: '${_selectedBirthDate.toLocal()}'
                        .split(' ')[0]), 
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
        ],
        onNext: _updateDogData,
      ),
    );
  }
}
