import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

// Core imports
import 'core/localization/app_localizations.dart';
import 'core/localization/localization_service.dart';
import 'core/theme/theme_service.dart';
import 'core/api/api_client.dart';

// Data layer imports
import 'data/repositories/task_repository.dart';
import 'data/datasources/task_remote_datasource.dart';

// Presentation layer imports
import 'presentation/providers/task_provider.dart';
import 'presentation/widgets/task_card.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize localization service
  final localizationService = LocalizationService();
  await localizationService.initialize();

  runApp(TaskManagerApp(localizationService: localizationService));
}

class TaskManagerApp extends StatelessWidget {
  final LocalizationService localizationService;

  const TaskManagerApp({super.key, required this.localizationService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Localization Service Provider
        ChangeNotifierProvider.value(value: localizationService),

        // API Client Provider
        Provider<ApiClient>(
          create: (_) => ApiClient(),
          dispose: (_, apiClient) => apiClient.dispose(),
        ),

        // Data Source Providers
        ProxyProvider<ApiClient, TaskRemoteDataSource>(
          update: (_, apiClient, __) =>
              TaskRemoteDataSourceImpl(apiClient: apiClient),
        ),

        // Repository Providers
        ProxyProvider<TaskRemoteDataSource, TaskRepository>(
          update: (_, dataSource, __) =>
              TaskRepositoryImpl(remoteDataSource: dataSource),
        ),

        // Business Logic Providers
        ChangeNotifierProxyProvider<TaskRepository, TaskProvider>(
          create: (context) =>
              TaskProvider(taskRepository: context.read<TaskRepository>()),
          update: (_, repository, previous) =>
              previous ?? TaskProvider(taskRepository: repository),
        ),
      ],
      child: Consumer<LocalizationService>(
        builder: (context, localizationService, child) {
          return MaterialApp(
            title: 'Task Manager',
            debugShowCheckedModeBanner: false,

            // Localization configuration
            locale: localizationService.currentLocale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // Theme configuration
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
              cardTheme: CardTheme(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),

            // Dark theme configuration
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
              cardTheme: CardTheme(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),

            // Home page
            home: const TaskManagerHomePage(),
          );
        },
      ),
    );
  }
}

class TaskManagerHomePage extends StatefulWidget {
  const TaskManagerHomePage({super.key});

  @override
  State<TaskManagerHomePage> createState() => _TaskManagerHomePageState();
}

class _TaskManagerHomePageState extends State<TaskManagerHomePage> {
  @override
  void initState() {
    super.initState();
    // Load tasks when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<LocalizationService>(
          builder: (context, localization, child) {
            return Text(context.tr('app.title'));
          },
        ),
        actions: [
          // Language selection
          PopupMenuButton<String>(
            onSelected: (languageCode) {
              context.read<LocalizationService>().changeLanguage(languageCode);
            },
            itemBuilder: (context) {
              return LocalizationService().availableLanguages.map((lang) {
                return PopupMenuItem<String>(
                  value: lang['code'],
                  child: Text(lang['nativeName']!),
                );
              }).toList();
            },
            child: const Icon(Icons.language),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          if (taskProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (taskProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    taskProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      taskProvider.clearError();
                      taskProvider.loadTasks();
                    },
                    child: Text(context.tr('common.retry')),
                  ),
                ],
              ),
            );
          }

          if (taskProvider.tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('tasks.noTasks'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('tasks.createFirstTask'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: taskProvider.tasks.length,
            itemBuilder: (context, index) {
              final task = taskProvider.tasks[index];
              return TaskCard(
                task: task,
                onTap: () {
                  // TODO: Navigate to task details
                },
                onEdit: () {
                  // TODO: Navigate to edit task
                },
                onDelete: () {
                  // TODO: Show delete confirmation
                },
                onToggleStatus: () {
                  taskProvider.toggleTaskStatus(task.id);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create task screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Extension for easy translation access
extension BuildContextExtensions on BuildContext {
  String tr(String key) {
    return AppLocalizations.of(this).translate(key);
  }
}
