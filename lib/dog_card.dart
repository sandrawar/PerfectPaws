import 'package:flutter/material.dart';
import 'package:perfect_paws/message_screen.dart';
import 'dog_class.dart';

class DogCard extends StatelessWidget {
  final Dog dog;
  final VoidCallback onFavoriteToggle;

  const DogCard({super.key, required this.dog, required this.onFavoriteToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Image.network(dog.imageUrl),
        title: Text(dog.name),
        subtitle: Text('${dog.age} years old'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                dog.isSaved ? Icons.star : Icons.star_border, 
                color: dog.isSaved ? Colors.yellow : Colors.grey,
              ),
              onPressed: onFavoriteToggle,
            ),
            IconButton(
              icon: const Icon(Icons.message),
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
