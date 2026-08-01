import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';

import 'providers/theme_provider.dart';
import 'providers/budget_provider.dart';
import 'services/voice_service.dart';
import 'services/screen_reader_service.dart';
import 'widgets/screen_reader_overlay.dart';



final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // Safety net: if any widget anywhere in the tree still throws during
  // build/layout/paint, show a small inline message instead of
  // Flutter's default full-screen translucent red mask, which blocks
  // the entire UI. This doesn't fix an underlying bug by itself -- it
  // just stops that class of bug from ever being able to block the
  // whole app again.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      color: const Color(0x11FF0000),
      child: const Text(
        "Something didn't load right here.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  };



  try {

    await dotenv.load(
      fileName: ".env",
    );

  } catch (e) {

    debugPrint(
      "No .env file found",
    );

  }




  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  await VoiceService.init();

  // Lets ScreenReaderService always resolve "the current screen" itself
  // (see screen_reader_service.dart) instead of every caller passing in
  // its own context, which is what previously let it read the wrong
  // screen/tab.
  ScreenReaderService.configure(navigatorKey);




  runApp(

    ChangeNotifierProvider(

      create: (_) => BudgetProvider(),

      child: const CharlieApp(),

    ),

  );

  // Attaches the floating "read screen" button as its own OverlayEntry
  // on the Navigator's existing Overlay -- the same mechanism Flutter
  // itself uses for SnackBars and Tooltips -- once the first frame has
  // been drawn and the Navigator/Overlay actually exist. This is the
  // key change from the previous approach: the button is a small,
  // self-contained sibling floating on top of whatever route is
  // showing, not a Stack wrapped around the app's own content, so a
  // problem in it can only ever affect its own small corner of the
  // screen and can never again replace or block the rest of the UI.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ScreenReaderOverlay.attach(navigatorKey);
  });

}






class CharlieApp extends StatelessWidget {


  const CharlieApp({

    super.key,

  });





  @override
  Widget build(BuildContext context) {


    return ValueListenableBuilder<bool>(


      valueListenable:

      ThemeProvider.isDarkMode,




      builder:

          (context, isDarkMode, child) {


        return MaterialApp(


          navigatorKey: navigatorKey,

          // Lets ScreenReaderService tell the route actually on top of
          // the stack apart from an earlier one Flutter is still
          // keeping mounted underneath it (see screen_reader_service.dart).
          navigatorObservers: [ScreenReaderService.routeObserver],


          debugShowCheckedModeBanner: false,


          title: "Charlie",



          themeMode:

          isDarkMode

              ? ThemeMode.dark

              : ThemeMode.light,





          theme: ThemeData(


            brightness:

            Brightness.light,



            primaryColor:

            const Color(0xFF2E7D32),



            scaffoldBackgroundColor:

            const Color(0xFFF5F7FA),



            colorScheme:

            ColorScheme.fromSeed(


              seedColor:

              const Color(0xFF2E7D32),



              brightness:

              Brightness.light,


            ),



            appBarTheme:

            const AppBarTheme(


              backgroundColor:

              Color(0xFF2E7D32),



              foregroundColor:

              Colors.white,



              elevation:

              0,


            ),


          ),








          darkTheme:

          ThemeData(


            brightness:

            Brightness.dark,



            primaryColor:

            const Color(0xFF2E7D32),



            scaffoldBackgroundColor:

            const Color(0xFF121212),



            colorScheme:

            ColorScheme.fromSeed(


              seedColor:

              const Color(0xFF2E7D32),



              brightness:

              Brightness.dark,


            ),



            appBarTheme:

            const AppBarTheme(


              backgroundColor:

              Color(0xFF2E7D32),



              foregroundColor:

              Colors.white,



              elevation:

              0,


            ),


          ),





          home:

          const SplashScreen(),



        );


      },


    );


  }


}