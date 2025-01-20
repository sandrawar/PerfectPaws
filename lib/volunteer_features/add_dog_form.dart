import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../dogs_list_logic/dog_class.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddDogForm extends StatefulWidget {
  const AddDogForm({super.key});

  @override
  AddDogFormState createState() => AddDogFormState();
}

class AddDogFormState extends State<AddDogForm> {
  final _nameController = TextEditingController();
  final _imageController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _volunteerController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  XFile? _image;
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  final ImagePicker _picker = ImagePicker();

  DateTime? _birthDate;
  bool _isEstimatedBirthDate = false;

  @override
  void initState() {
    super.initState();
    _setVolunteerEmail();
    _initializeCamera();
  }

  void _setVolunteerEmail() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _volunteerController.text = user.email ?? '';
    }
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras[0], ResolutionPreset.high);
    await _controller!.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
  }

  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized) {
      return;
    }

    try {
      final XFile photo = await _controller!.takePicture();
      setState(() {
        _image = photo;
        _imageController.text = photo.path;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error")),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    final localizations = AppLocalizations.of(context)!;
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = pickedFile;
          _imageController.text = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.error)),
        );
      }
    }
  }

  Future<String> _uploadImageToFirebase(XFile image) async {
    final localizations = AppLocalizations.of(context)!;
    try {
      final file = File(image.path);
      final storageReference = FirebaseStorage.instance
          .ref()
          .child('dogs_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageReference.putFile(file);

      final imageUrl = await storageReference.getDownloadURL();
      return imageUrl;
    } catch (e) {
      throw Exception(localizations.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(localizations!.addDog),
      content: Form(
        key: _formKey,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: _buildStepContent(_currentStep, localizations),
        ),
      ),
      actions: [
        if (_currentStep > 0)
          TextButton(
            onPressed: _previousStep,
            child: Text(localizations.prev),
          ),
        if (_currentStep < 2)
          TextButton(
            onPressed: _nextStep,
            child: Text(localizations.next),
          ),
        if (_currentStep == 2)
          TextButton(
            onPressed: _submitForm,
            child: Text(localizations.add),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(localizations.cancel),
        ),
      ],
    );
  }

  Widget _buildStepContent(int step, AppLocalizations localizations) {
    final formattedDate =
        DateFormat.yMMMMd(localizations.localeName).format(DateTime.now());
    switch (step) {
      case 0:
        return Column(
          key: const ValueKey(0),
          children: [
            TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: localizations.dogsName),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.dogsNameNullCheck;
                  }
                  return null;
                }),
            TextFormField(
                controller: _descriptionController,
                decoration:
                    InputDecoration(labelText: localizations.dogsDescription),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.dogsDescriptionNullCheck;
                  }
                  return null;
                },
                maxLines: 7),
            TextFormField(
                controller: _locationController,
                decoration:
                    InputDecoration(labelText: localizations.dogsLocation),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.dogsLocationNullCheck;
                  }
                  if (!RegExp(r'^[A-Z]').hasMatch(value)) {
                    return localizations.locationCapitalLetterCheck;
                  }
                  return null;
                }),
          ],
        );
      case 1:
        return Column(
          key: const ValueKey(1),
          children: [
            if (_isCameraInitialized && _image == null) ...[
              SizedBox(
                height: 300,
                width: double.infinity,
                child: CameraPreview(_controller!),
              ),
              ElevatedButton(
                onPressed: _takePicture,
                child: Text(localizations.takePicture),
              ),
              ElevatedButton(
                onPressed: _pickImageFromGallery,
                child: Text(localizations.choosePicture),
              ),
            ],
            if (_image != null) ...[
              Image.file(
                File(_image!.path),
                height: 150,
                width: 150,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _image = null;
                  });
                },
                child: Text(localizations.takePicture),
              ),
            ],
          ],
        );
      case 2:
        return Column(
          key: const ValueKey(2),
          children: [
            Text(localizations.dogsBirthDate),
            TextButton(
              onPressed: _selectBirthDate,
              child: Text(_birthDate != null
                  ? formattedDate
                  : localizations.chooseDate),
            ),
            SwitchListTile(
              title: Text(localizations.isEstimated),
              value: _isEstimatedBirthDate,
              onChanged: (value) {
                setState(() {
                  _isEstimatedBirthDate = value;
                });
              },
            ),
            TextFormField(
              controller: _volunteerController,
              decoration: InputDecoration(labelText: localizations.volunteer),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.volunteerNullCheck;
                }
                return null;
              },
              enabled: false,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    setState(() {
      _currentStep--;
    });
  }

  void _submitForm() async {
    final localizations = AppLocalizations.of(context);
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final description = _descriptionController.text;
      final location = _locationController.text;
      final volunteer = _volunteerController.text;

      String? imageUrl = '';
      if (_image != null) {
        imageUrl = await _uploadImageToFirebase(_image!);
      }

      final dog = Dog(
        name: name,
        imageUrl: imageUrl,
        birthDate: Timestamp.fromDate(_birthDate!),
        isEstimatedBirthDate: _isEstimatedBirthDate,
        numberOfSaves: 0,
        volunteer: volunteer,
        description: description,
        location: location,
      );

      try {
        await FirebaseFirestore.instance.collection('dogs').add(dog.toMap());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations!.dogAdded)),
          );
        }
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${localizations!.error}: $e')),
          );
        }
      }
    }
  }
}
