// ignore_for_file: invalid_use_of_protected_member, use_build_context_synchronously, invalid_use_of_visible_for_testing_member

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:ping_chat/bloc/Devices_list/devices_list_cubit.dart';
import 'package:ping_chat/bloc/Message_cubit/message_cubit.dart';
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
            Future.delayed(const Duration(seconds: 10), () {
              if (mounted &&
                  context.read<DevicesListCubit>().state
                      is DevicesListLoadingState) {
                context.read<DevicesListCubit>().emit(
                  DevicesListSuccessState(devices: {}),
                );
              }
            });
            return Center(
              child: Lottie.asset('assets/animations/loading.json'),
            );
          }
          if (state is DevicesListSuccessState) {
            final devices = state.devices;
            return devices.isEmpty
                ? Center(
                  child: Column(
                    children: [
                      Lottie.asset('assets/animations/no data.json'),
                      Text('No Devices Found', style: TextStyle(fontSize: 30)),
                    ],
                  ),
                )
                : ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final ip = devices.keys.elementAt(index);
                    final name = devices[ip]!;

                    return BlocBuilder<MessageCubit, MessageState>(
                      builder: (context, msgState) {
                        bool hasUnread = false;

                        if (msgState is MessageUpdated) {
                          hasUnread = msgState.unreadIPs.contains(ip);
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            radius: 25,
                            child: Center(
                              child: Text(
                                name[0],
                                style: TextStyle(fontSize: 25),
                              ),
                            ),
                          ),
                          title: Text(name),
                          subtitle: Text(ip),
                          trailing:
                              hasUnread
                                  ? CircleAvatar(radius: 15, child: Text("?"))
                                  : null,
                          onTap: () {
                            context.read<MessageCubit>().markAsRead(ip);
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
