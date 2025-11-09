import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notiveapp/models/category_model.dart';
import 'package:notiveapp/models/task_model.dart';
import 'package:notiveapp/pages/home_page.dart';
import 'package:notiveapp/services/notifications_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const int _minimumDisplayTimeMs = 2000;
  @override
  void initState() {
    super.initState();
    // 1. Start loading all the app services
    _loadDataAndNavigate();
  }

  // 2. This function now does the "heavy lifting"
  Future<void> _loadAppServices() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(CategoryAdapter());

    try {
      await Hive.openBox<Task>('tasksBox');
    } catch (e) {
      debugPrint("⚠️ Hive box 'tasksBox' corrupted: $e");
      await Hive.deleteBoxFromDisk('tasksBox');
      await Hive.openBox<Task>('tasksBox');
    }

    try {
      await Hive.openBox<Category>('categoriesBox');
    } catch (e) {
      debugPrint("⚠️ Hive box 'categoriesBox' corrupted: $e");
      await Hive.deleteBoxFromDisk('categoriesBox');
      await Hive.openBox<Category>('categoriesBox');
    }

    // Also open the order box
    try {
      await Hive.openBox('taskOrderBox');
    } catch (e) {
      debugPrint("⚠️ Hive box 'taskOrderBox' corrupted: $e");
      await Hive.deleteBoxFromDisk('taskOrderBox');
      await Hive.openBox('taskOrderBox');
    }

    await NotificationService.init();
  }

  Future<void> _loadDataAndNavigate() async {
    // 3. Wait for all the services to load
    final minimumTimeFuture = Future.delayed(
      const Duration(milliseconds: _minimumDisplayTimeMs),
    );
    final dataLoadingFuture = _loadAppServices();

    await Future.wait([minimumTimeFuture, dataLoadingFuture]);

    // 4. navigate to the HomePage
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  // 5. UI
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt_rounded, size: 80, color: cs.primary),
            const SizedBox(height: 24),
            Text(
              'Notive',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your daily task manager',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(color: cs.primary),
          ],
        ),
      ),
    );
  }
}
