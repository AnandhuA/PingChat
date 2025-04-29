import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ping_chat/bloc/Devices_list/devices_list_cubit.dart';
import 'package:ping_chat/main.dart';
import 'package:ping_chat/screen/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.name});
  final String name;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DevicesListCubit>().discoverDevices(name: widget.name);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // _discoverDevices();
              context.read<DevicesListCubit>().discoverDevices(
                name: widget.name,
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<DevicesListCubit, DevicesListState>(
        builder: (context, state) {
          log("$state");
          if (state is DevicesListLoadingState) {
            return Center(child: CircularProgressIndicator());
          }
          if (state is DevicesListSuccessState) {
            final devices = state.devices;
            return devices.isEmpty
                ? const Center(child: Text('No devices found'))
                : ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final ip = devices.keys.elementAt(index);
                    final name = devices[ip]!;
                    return ListTile(
                      leading: const Icon(Icons.device_hub),
                      title: Text(name),
                      subtitle: Text(ip),

                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ChatScreen(
                                  peerIP: ip,
                                  server: server,
                                  peerName: name,
                                ),
                          ),
                        );
                      },
                    );
                  },
                );
          } else {
            return Center(child: Text("error"));
          }
        },
      ),
    );
  }
}
