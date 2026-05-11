import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:coop_commerce/config/router.dart';
import 'package:coop_commerce/core/api/service_locator.dart';
import 'package:coop_commerce/core/error/exception_handler.dart';
import 'package:coop_commerce/core/services/fcm_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/features/notifications/notification_screens.dart';
import 'package:coop_commerce/features/welcome/auth_provider.dart';
import 'package:coop_commerce/providers/app_settings_provider.dart';
import 'package:coop_commerce/providers/app_initializer_provider.dart';
import 'package:coop_commerce/services/local_search_preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('📱 App starting...');

  // Setup global exception handler
  ExceptionHandler.setupGlobalExceptionHandler();

  // Initialize Firebase - with error handling
  try {
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp();
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      );
      print('✅ Firebase App Check initialized');
    } catch (e) {
      debugPrint('⚠️ Firebase App Check initialization warning: $e');
    }
    print('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Firebase initialization failed: $e');
    print(
        '⚠️ Firebase initialization failed - app will run with reduced functionality');
    // Don't crash - let the app run anyway
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _startedBootstrap = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_startedBootstrap) {
        return;
      }
      _startedBootstrap = true;
      unawaited(_bootstrapDeferredStartup());
    });
  }

  Future<void> _bootstrapDeferredStartup() async {
    unawaited(ref.read(initializePersistedUserProvider.future));
    ref.read(appInitializerProvider);

    await Future<void>.delayed(const Duration(milliseconds: 150));

    // Initialize search preferences (for role-specific recent searches and pinned intents)
    try {
      print('🔍 Initializing search preferences...');
      final searchPrefs = LocalSearchPreferencesService();
      await searchPrefs.init();
      print('✅ Search preferences initialized');
    } catch (e) {
      debugPrint('Search preferences initialization warning: $e');
    }

    try {
      print('🔧 Initializing service locator...');
      serviceLocator.initialize();
      print('✅ Service locator initialized');
    } catch (e) {
      debugPrint('Service locator initialization error: $e');
    }

    await Future<void>.delayed(const Duration(milliseconds: 150));

    try {
      final fcmService = FCMService();
      await fcmService.initialize();
      print('✅ FCM initialized');
    } catch (e) {
      debugPrint('FCM initialization warning: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch dark mode setting
    final isDarkMode = ref.watch(darkModeProvider);

    final router = AppRouter.createRouter(ref);

    // Define light theme - comprehensive with all UI elements
    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
      ),
      cardTheme: CardThemeData(
        color: Colors.grey[50],
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.white,
        textColor: Colors.black,
        iconColor: Colors.black,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF1F2937)),
        bodyMedium: TextStyle(color: Color(0xFF1F2937)),
        bodySmall: TextStyle(color: Color(0xFF6B7280)),
      ),
    );

    // Define dark theme - comprehensive with all UI elements
    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      canvasColor: const Color(0xFF1E1E1E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: Color(0xFF7C3AED),
        unselectedItemColor: Colors.grey,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2A2A2A),
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF3A3A3A),
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Color(0xFF2A2A2A),
        textColor: Colors.white,
        iconColor: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Color(0xFFB0B0B0)),
      ),
    );

    return MaterialApp.router(
      title: 'Coop Commerce',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        return InAppNotificationBanner(
          child: child!,
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
