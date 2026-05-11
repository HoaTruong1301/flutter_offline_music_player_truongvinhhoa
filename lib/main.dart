import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/audio_provider.dart';
import 'providers/playlist_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'services/audio_player_service.dart';
import 'services/storage_service.dart';
import 'services/playlist_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider(create: (_) => StorageService()),
        ProxyProvider<StorageService, PlaylistService>(
          update: (_, storage, __) => PlaylistService(storage),
        ),
        Provider(
          create: (_) => AudioPlayerService(),
          dispose: (_, service) => service.dispose(),
        ),
        ChangeNotifierProvider(
          create: (context) => AudioProvider(
            Provider.of<AudioPlayerService>(context, listen: false),
            Provider.of<StorageService>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => PlaylistProvider(
            Provider.of<PlaylistService>(context, listen: false),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'Music Player',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const HomeScreen(),
    );
  }
}
