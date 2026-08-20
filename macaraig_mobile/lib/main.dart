import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:macaraig_mobile/screens/home_screen.dart';
import 'package:macaraig_mobile/screens/settings_screen.dart';
import 'package:macaraig_mobile/screens/splash_screen.dart';
import 'package:macaraig_mobile/screens/signin_screen.dart';

import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await dotenv.load(fileName: 'assets/.env');

  runApp(const MacaraigAdvMobProg());
}

class MacaraigAdvMobProg extends StatelessWidget {
  const MacaraigAdvMobProg({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: ScreenUtilInit(
        designSize: const Size(412, 715),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          final themeModel = context.watch<ThemeProvider>();

          return MaterialApp(
            debugShowCheckedModeBanner: false,

            title: 'E-Commerce App',

            theme: ThemeData.light(),

            darkTheme: ThemeData.dark(),

            themeMode: themeModel.isDark
                ? ThemeMode.dark
                : ThemeMode.light,

            // Activity 4:
            // Start with Splash Screen to check
            // persistent authentication.
            initialRoute: '/splash',

            routes: {
              '/splash': (context) => const SplashScreen(),

              '/signin': (context) => const SignInScreen(),

              '/home': (context) => const HomeScreen(),

              '/settings': (context) => SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}