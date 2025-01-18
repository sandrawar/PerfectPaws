import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:perfect_paws/menu_screen.dart';
import '../dogs_list_logic/dog_class.dart';
import 'add_dog_form.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class VolunteerDogsListScreen extends StatefulWidget {
  const VolunteerDogsListScreen({super.key});

  @override
  _VolunteerDogsListScreenState createState() =>
      _VolunteerDogsListScreenState();
}

class _VolunteerDogsListScreenState extends State<VolunteerDogsListScreen> 
with SingleTickerProviderStateMixin{

  
  late AnimationController animationController;
  late User _currentUser;
  late Stream<QuerySnapshot> _dogsStream;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser!;
    _getDogsForVolunteer();
    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250),
    );
  }

  void toggle() => animationController.isDismissed
  ? animationController.forward()
  : animationController.reverse();

  final double maxSlide = 225.0;

  void _getDogsForVolunteer() {
    _dogsStream = FirebaseFirestore.instance
        .collection('dogs')
        .where('volunteer', isEqualTo: _currentUser.email)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    
  final localizations = AppLocalizations.of(context);
    var myChild = Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(197, 174, 174, 1),
        automaticallyImplyLeading: false,
        leading:
          IconButton(
            alignment: Alignment.topLeft,
        icon: Icon( Icons.menu, color: Colors.white,),
        onPressed: () {
          toggle();
        },
      ),
        title: Text(localizations!.myDogs, 
    style: TextStyle(color: Colors.white),),
      ),
  backgroundColor: Color.fromRGBO(188, 104, 104, 1),
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
              return Padding(
                padding: const EdgeInsetsDirectional.all(16),
                child: Card(
      color: Color.fromRGBO(197, 174, 174, 1),
      child: ListTile(
        //tileColor: Color.fromRGBO(197, 174, 174, 10),
        leading: ClipOval(
          child: Image.network(dog.imageUrl,
    width: 50.0, // Szerokość obrazu
    height: 50.0, // Wysokość obrazu
    fit: BoxFit.cover,)),
                title: Text(dog.name, 
    style: TextStyle(color: Colors.white),),
                subtitle: Text('${localizations.numberOfSaves}: ${dog.numberOfSaves}', 
    style: TextStyle(color: Colors.white),),
                onTap: () {
                  context.go(
                    '/dog-details/${dog.id}',
                    extra: dog,
                  );
                },

      ),
    ),); 
  
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
    var myDrawer = MenuScreen();
     return GestureDetector(
      onTap: toggle,
      child: AnimatedBuilder(
    animation: animationController,
    builder: (context, _){
      double slide = maxSlide*animationController.value;
      double scale = 1 - (animationController.value * 0.3);
    return Stack(
      children: <Widget>[
        myDrawer,
        Transform(
          transform: Matrix4.identity()
          ..translate(slide)
          ..scale(scale),
          alignment: Alignment.centerLeft,
          child: myChild,)
      ],
    );
  }
  )
    );
  }
  }

