import 'package:flutter/material.dart';
import 'package:perfect_paws/dogs_list_logic/dog_card.dart';
import 'package:perfect_paws/dogs_list_logic/dog_class.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DogSearchDelegate extends SearchDelegate {
  final String searchQuery;
  final Future<List<Dog>> Function(String query) getDogsFromFirebase;
  final Function(Dog) toggleSaved;

  DogSearchDelegate(this.searchQuery, this.getDogsFromFirebase,
      this.toggleSaved, BuildContext context);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(188, 104, 104, 1),
      body: FutureBuilder<List<Dog>>(
        future: getDogsFromFirebase(query),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }

          final dogs = snapshot.data ?? [];

          if (dogs.isEmpty) {
            return Center(
                child: Text(localizations.emptySearch,
                    style: const TextStyle(color: Colors.white)));
          }

          return ListView.builder(
            itemCount: dogs.length,
            itemBuilder: (context, index) {
              final dog = dogs[index];
              return DogCard(
                dog: dog,
                onFavoriteToggle: () {
                  toggleSaved(dog);
                },
                isFavorite: dog.isSaved,
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(188, 104, 104, 1),
      body: FutureBuilder<List<Dog>>(
        future: getDogsFromFirebase(query),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('${localizations.error}: ${snapshot.error}'));
          }

          final dogs = snapshot.data ?? [];

          return ListView.builder(
            itemCount: dogs.length,
            itemBuilder: (context, index) {
              final dog = dogs[index];
              return Padding(
                  padding: const EdgeInsets.all(16),
                  child: DogCard(
                    dog: dog,
                    onFavoriteToggle: () {
                      toggleSaved(dog);
                    },
                    isFavorite: dog.isSaved,
                  ));
            },
          );
        },
      ),
    );
  }

  @override
  String get searchFieldLabel => 'Search location';

  @override
  TextStyle get searchFieldStyle => const TextStyle(color: Colors.white);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        color: Color.fromRGBO(197, 174, 174, 1),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        toolbarTextStyle: TextStyle(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white),
      ),
    );
  }
}
