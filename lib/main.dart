import "exts.dart";
import "rust/frb_generated.dart";
import "src/app_theme.dart";
import "src/cubits/settings_cubit.dart";
import "src/cubits/tracing_cubit.dart";
import "src/presentation/home/home_screen.dart";
import "src/services/other_service.dart";
import "src/services/tracing_service.dart";
import "src/services/transfer_service.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => TransferService()),
        RepositoryProvider(create: (context) => TracingService()),
        RepositoryProvider(create: (context) => OtherService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            lazy: false,
            create: (context) => TracingCubit(context.read()),
          ),
          BlocProvider(
            create: (context) => SettingsCubit(
              context.read(),
              onConnectivityLost: (addr) {
                navigatorKey.currentContext?.showWarningSnackBar(
                  "Lost connection to $addr",
                );
              },
            ),
          ),
        ],
        child: BlocBuilder<SettingsCubit, SettingsState>(
          buildWhen: (previous, current) =>
              previous.themeMode != current.themeMode,
          builder: (context, state) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              title: "Drop Plus",
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: state.themeMode,
              builder: (context, child) {
                return ScrollConfiguration(
                  behavior: const ScrollBehavior().copyWith(scrollbars: true),
                  child: child!,
                );
              },
              home: const HomeScreen(),
            );
          },
        ),
      ),
    );
  }
}
