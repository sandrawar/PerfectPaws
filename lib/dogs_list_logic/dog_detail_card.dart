import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:perfect_paws/dogs_list_logic/dog_class.dart';
import 'package:perfect_paws/volunteer_features/item_fader.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

abstract class DogDetailsCard {
  static void showDogDetails(Dog dog, context, Function onFavoriteToggle) {
    final localizations = AppLocalizations.of(context)!;
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
                '${localizations.dogsBirthDate}: ${DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(dog.birthDate.toDate())}'
                '${dog.isEstimatedBirthDate ? " (${localizations.estimatedDate})" : ""}',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                '${localizations.dogsDescription}: ${dog.description}',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                '${localizations.dogsLocation}: ${dog.location}',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  onFavoriteToggle(dog);
                  Navigator.of(context).pop();
                },
                child: Text(dog.isSaved
                    ? localizations.deleteFromSaved
                    : localizations.saveDog),
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
