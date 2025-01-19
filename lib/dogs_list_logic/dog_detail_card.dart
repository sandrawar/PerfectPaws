import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:perfect_paws/dogs_list_logic/dog_class.dart';
import 'package:perfect_paws/volunteer_features/item_fader.dart';

abstract class DogDetailsCard {
  static void showDogDetails(Dog dog, context, Function onFavoriteToggle) {
    showDialog(
      context: context,
      builder: (context) {
        return Scaffold(
          body: MyPage(
            elements: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dog.name,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  IconButton(
                    alignment: Alignment.topRight,
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (dog.imageUrl.isNotEmpty)
                ClipOval(
                  child: Image.network(
                    dog.imageUrl,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 20),
              const SizedBox(height: 16),
              Text(
                'Wiek: ${DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(dog.birthDate.toDate())}',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'Opis: ${dog.description}',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'Lokalizacja: ${dog.location}',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  onFavoriteToggle(dog); // Zapisuje psa
                  Navigator.of(context).pop(); // Zamykamy dialog
                },
                child: Text(dog.isSaved ? 'Usuń z zapisanych' : 'Zapisz psa'),
              ),
            ],
            onNext: () {
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }
}
