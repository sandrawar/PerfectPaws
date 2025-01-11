import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.settings ?? 'Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('English'),
            trailing: currentLocale == 'en' ? const Icon(Icons.check) : null,
            onTap: () => localeProvider.setLocale(const Locale('en')),
          ),
          ListTile(
            title: Text('Polski'),
            trailing: currentLocale == 'pl' ? const Icon(Icons.check) : null,
            onTap: () => localeProvider.setLocale(const Locale('pl')),
          ),
          ListTile(
            title: Text('Espańol'),
            trailing: currentLocale == 'es' ? const Icon(Icons.check) : null,
            onTap: () => localeProvider.setLocale(const Locale('es')),
          ),
        ],
      ),
    );
  }
}
