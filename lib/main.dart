import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_config.dart';
import 'controllers/meteorology_controller.dart';
import 'services/meteorology_service.dart';
import 'ui/screens/main_screen.dart';
import 'models/meteorology_state.dart';

void main() {
  runApp(const MeteorologicalSandbox());
}

class MeteorologicalSandbox extends StatelessWidget {
  const MeteorologicalSandbox({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MeteorologyController()),
        Provider(create: (_) => MeteorologyService()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}