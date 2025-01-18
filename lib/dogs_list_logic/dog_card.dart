import 'package:flutter/material.dart';
import 'package:perfect_paws/messages/message_screen.dart';
import 'dog_class.dart';

class DogCard extends StatelessWidget {
  final Dog dog;
  final VoidCallback onFavoriteToggle;
  final bool isFavorite;

  const DogCard({super.key, required this.dog, required this.onFavoriteToggle, required this.isFavorite,});

  @override
  Widget build(BuildContext context) {
    return Card(
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
        subtitle: Text('${dog.age} years old', 
    style: TextStyle(color: Colors.white),),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border, 
                color: isFavorite ? Colors.yellow : Colors.grey,
              ),
              onPressed: onFavoriteToggle,
            ),
            IconButton(
              icon: const Icon(Icons.message, color: Colors.white,),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessageScreen(volunteerEmail: dog.volunteer),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
