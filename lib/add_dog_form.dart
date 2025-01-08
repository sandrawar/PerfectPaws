import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:camera/camera.dart';
import 'dart:io';  // Do obsługi plików
import 'dog_class.dart';
import 'package:image_picker/image_picker.dart';  // Importujemy image_picker

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
  XFile? _image; // Do przechowywania zdjęcia
  CameraController? _controller;  // Kontroler kamery
  List<CameraDescription> _cameras = [];  // Lista kamer
  bool _isCameraInitialized = false;
  final ImagePicker _picker = ImagePicker(); // Inicjalizujemy image_picker

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
    _cameras = await availableCameras();  // Pobieramy dostępne kamery
    _controller = CameraController(_cameras[0], ResolutionPreset.high);  // Wybieramy pierwszą kamerę
    await _controller!.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
  }

  // Funkcja robienia zdjęcia
  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized) {
      print("Kamera nie została zainicjowana.");
      return;
    }

    try {
      final XFile photo = await _controller!.takePicture();
      setState(() {
        _image = photo;
        _imageController.text = photo.path; 
      });
    } catch (e) {
      print("Błąd przy robieniu zdjęcia: $e");
    }
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
      print("Błąd przy wyborze zdjęcia z galerii: $e");
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
      print("Błąd przy wysyłaniu zdjęcia: $e");
      throw Exception("Nie udało się przesłać zdjęcia do Firebase Storage");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dodaj psa'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_currentStep == 0) ...[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Imię psa'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Proszę podać imię psa';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Opis psa'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Proszę podać opis psa';
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
                child: const Text('Zrób zdjęcie psa'),
              ),
              ElevatedButton(
                onPressed: _pickImageFromGallery,
                child: const Text('Wybierz zdjęcie z galerii'),
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
                decoration: const InputDecoration(labelText: 'Lokalizacja psa'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Proszę podać lokalizację psa';
                  }
                  return null;
                },
              ),
            ] else if (_currentStep == 2) ...[
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Wiek psa'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Proszę podać wiek psa';
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _volunteerController,
                decoration: const InputDecoration(labelText: 'Wolontariusz'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Proszę podać nazwisko wolontariusza';
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
            child: const Text('Wstecz'),
          ),
        if (_currentStep < 2)
          TextButton(
            onPressed: _nextStep,
            child: const Text('Dalej'),
          ),
        if (_currentStep == 2)
          TextButton(
            onPressed: _submitForm,
            child: const Text('Dodaj'),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Anuluj'),
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
          const SnackBar(content: Text('Pies dodany!')),
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
