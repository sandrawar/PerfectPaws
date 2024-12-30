import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isVolunteer = false; 

  Future<void> _register() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    await saveUserData(userCredential.user!, _isVolunteer);
    await createMessagesSubCollection(userCredential.user!);
    context.go('/login');
  } on FirebaseAuthException catch (e) {
    setState(() {
      _errorMessage = e.message;
    });
  } catch (e) {
    setState(() {
      _errorMessage = 'Wystąpił błąd podczas rejestracji.';
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}


  Future<void> saveUserData(User user, bool isVolunteer) async {
    final usersCollection = FirebaseFirestore.instance.collection('users');

    await usersCollection.doc(user.uid).set({
      'email': user.email,
      'isVolunteer': isVolunteer,
    }, SetOptions(merge: true));
  }

  Future<void> createMessagesSubCollection(User user) async {
  try {
    final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    
    final messagesSubCollection = userDocRef.collection('messages');
    
    await messagesSubCollection.add({
      'message': 'Witaj! Twoje konto zostało utworzone.',
      'timestamp': FieldValue.serverTimestamp(),
    });

    print('Subkolekcja messages dla użytkownika ${user.uid} została utworzona.');
  } catch (e) {
    print('Błąd przy tworzeniu subkolekcji messages: $e');
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rejestracja'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Hasło',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Czy jesteś wolontariuszem?'),
                  Checkbox(
                    value: _isVolunteer,
                    onChanged: (value) {
                      setState(() {
                        _isVolunteer = value ?? false;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _register, 
                  child: const Text('Zarejestruj się'),
                ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              TextButton(
                onPressed: () {
                  context.go('/login');
                },
                child: const Text('Masz już konto? Zaloguj się'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
