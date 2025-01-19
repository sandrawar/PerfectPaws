import 'package:flutter/material.dart';
import 'package:perfect_paws/menu_screen.dart';
import 'package:provider/provider.dart';
import 'locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  void toggle() => animationController.isDismissed
      ? animationController.forward()
      : animationController.reverse();

  final double maxSlide = 225.0;
  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale.languageCode;
    var myChild = Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(197, 174, 174, 1),
        automaticallyImplyLeading: false,
        leading: IconButton(
          alignment: Alignment.topLeft,
          icon: const Icon(Icons.menu),
          color: Colors.white,
          onPressed: () {
            toggle();
          },
        ),
        title: Text(AppLocalizations.of(context)?.settings ?? 'Settings', style: const TextStyle(color: Colors.white)),
      ),
      backgroundColor: const Color.fromRGBO(188, 104, 104, 1),
      body: ListView(
        children: [
          ListTile(
            title: const Text('English', style: TextStyle(color: Colors.white)),
            trailing: currentLocale == 'en' ? const Icon(Icons.check) : null,
            onTap: () => localeProvider.setLocale(const Locale('en')),
          ),
          ListTile(
            title: const Text('Polski', style: TextStyle(color: Colors.white)),
            trailing: currentLocale == 'pl' ? const Icon(Icons.check) : null,
            onTap: () => localeProvider.setLocale(const Locale('pl')),
          ),
          ListTile(
            title: const Text('Espańol', style: TextStyle(color: Colors.white)),
            trailing: currentLocale == 'es' ? const Icon(Icons.check) : null,
            onTap: () => localeProvider.setLocale(const Locale('es')),
          ),
        ],
      ),
    );
    return MenuScreen.animatedMenu(
        myChild, MenuScreen(), maxSlide, toggle, animationController);
  }
}
