import 'dart:io';

import 'package:boilerplate/presentation/constants/strings.dart';
import 'package:boilerplate/presentation/utils/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'constants/app_theme.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {



  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    HttpOverrides.global = MyHttpOverrides();

    return Observer(
      builder: (context) {
        return Stack(
          children: [
            MaterialApp.router(
              routerConfig: Routes.routes,
              debugShowCheckedModeBanner: false,
              title: Strings.appName,
              theme: AppThemeData.darkThemeData,
              // locale: Locale(_languageStore.locale),
              // supportedLocales: _languageStore.supportedLanguages
              //     .map((language) => Locale(language.locale, language.code))
              //     .toList(),
              // localizationsDelegates: [
              //   AppLocalizations.delegate,
              //   GlobalMaterialLocalizations.delegate,
              //   GlobalWidgetsLocalizations.delegate,
              //   GlobalCupertinoLocalizations.delegate,
              // ],
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
                  child: child!,
                );
              },
            ),
            //FloatingWindow(),
          ],
        );
      },
    );
  }
}
