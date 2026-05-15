import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'providers/audio_provider.dart';
import 'providers/playlist_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'services/audio_player_service.dart';
import 'services/storage_service.dart';
import 'services/playlist_service.dart';
import 'services/audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  AudioHandler? audioHandler;
  String? initError;

  try {
    debugPrint("🚀 [Main] Đang khởi tạo AudioService...");
    // Khởi tạo một lần duy nhất, không dùng timeout lồng nhau
    audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.music_player.channel.audio',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        notificationColor: Colors.green,
      ),
    );
    debugPrint("✅ [Main] AudioService khởi tạo thành công.");
  } catch (e) {
    debugPrint("❌ [Main] Lỗi khởi tạo AudioService: $e");
    initError = e.toString();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider(create: (_) => StorageService()),
        ProxyProvider<StorageService, PlaylistService>(
          update: (_, storage, __) => PlaylistService(storage),
        ),
        Provider(
          create: (_) {
            final service = AudioPlayerService();
            if (audioHandler != null) {
              service.init(audioHandler as MyAudioHandler);
            }
            return service;
          },
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
      child: MyApp(initError: initError),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String? initError;
  const MyApp({super.key, this.initError});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'Music Player',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      // Nếu có lỗi khởi tạo, hiện thông báo lỗi cụ thể thay vì màn hình trắng
      home: initError != null 
        ? Scaffold(
            backgroundColor: const Color(0xFF191414),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      "Lỗi khởi tạo hệ thống nhạc:\n$initError",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => main(), // Thử lại
                      child: const Text("Thử lại"),
                    )
                  ],
                ),
              ),
            ),
          )
        : const HomeScreen(),
    );
  }
}
