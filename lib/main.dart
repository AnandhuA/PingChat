import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ping_chat/bloc/Devices_list/devices_list_cubit.dart';
import 'package:ping_chat/bloc/Message_cubit/message_cubit.dart';
import 'package:ping_chat/screen/splash_screen.dart';
import 'package:ping_chat/server.dart';
import 'package:ping_chat/theme/theme_class.dart';

final server = Server();
MessageCubit? messageCubitGlobal;
void main() {
  // server.startServer();
  // server.onGlobalMessageReceived = (ip, message) {
  //   // Use Bloc directly via global context
  //   messageCubitGlobal?.addMessage(ip, message); // Define below
  // };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => DevicesListCubit()),
        BlocProvider(
          create: (context) {
            final cubit = MessageCubit();
            messageCubitGlobal = cubit;
            return cubit;
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Now safe to start server
            server.startServer();
            server.onGlobalMessageReceived = (ip, message) {
              messageCubitGlobal?.addMessage(ip, message);
            };
          });

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SplashScreen(),
            themeMode: ThemeMode.system,
            theme: ThemeClass.lightTheme,
            darkTheme: ThemeClass.darkTheme,
          );
        },
      ),
    );
  }
}
