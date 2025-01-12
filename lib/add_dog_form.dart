import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:camera/camera.dart';
import 'dart:io';  
import 'dog_class.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';  

class AddDogForm extends StatefulWidget {
  const AddDogForm({super.key});

  @override
  _AddDogFormState createState() => _AddDogFormState();
}

class _AddDogFormState extends State<AddDogForm> {
  final _nameController = TextEditingController();
  final _imageController = TextEditingController();
  final _ageController = TextEditingController();
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
    } catch (e) {}
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = pickedFile;
          _imageController.text = pickedFile.path;
        });
      }
    } catch (e) {
    }
  }

  Future<String> _uploadImageToFirebase(XFile image) async {
    try {
      final file = File(image.path);
      final storageReference = FirebaseStorage.instance
          .ref()
          .child('dogs_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await storageReference.putFile(file);

      final imageUrl = await storageReference.getDownloadURL();
      return imageUrl;
    } catch (e) {
      throw Exception("Nie udało się przesłać zdjęcia do Firebase Storage");
    }
  }

  @override
  Widget build(BuildContext context) {
    
  final localizations = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(localizations!.addDog),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_currentStep == 0) ...[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: localizations.dogsName),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.dogsNameNullCheck;
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: localizations.dogsDescription),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.dogsDescriptionNullCheck;
                  }
                  return null;
                },
              ),
            ] else if (_currentStep == 1) ...[
              if (_isCameraInitialized)
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
              if (_image != null) ...[
                Image.file(
                  File(_image!.path),
                  height: 150,
                  width: 150,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 10),
              ],
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: localizations.dogsLocation),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.dogsLocationNullCheck;
                  }
                  return null;
                },
              ),
            ] else if (_currentStep == 2) ...[
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(labelText: localizations.dogsAge),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.dogsAgeNullCheck;
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
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
          ],
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
      final age = int.parse(_ageController.text);
      final location = _locationController.text; 
      final volunteer = _volunteerController.text;

      String? imageUrl = '';
      if (_image != null) {
        imageUrl = await _uploadImageToFirebase(_image!);
      }

      final dog = Dog(
        name: name,
        imageUrl: imageUrl,
        age: age,
        numberOfSaves: 0,
        volunteer: volunteer,
        description: description, 
        location: location, 
      );

      try {
        await FirebaseFirestore.instance.collection('dogs').add(dog.toMap());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations!.dogAdded)),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e')),
        );
      }
    }
  }
}
