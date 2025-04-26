import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:ping_chat/main.dart';
import 'package:ping_chat/screen/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.name});
  final String name;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, String> _devices = {}; // IP -> Name mapping
  bool _isScanning = false;
  String? _localIP;
  late List<Socket> _openSockets;

  @override
  void initState() {
    _openSockets = [];
    _getLocalIP();
    super.initState();
    _discoverDevices();
  }

  Future<void> _getLocalIP() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.isLoopback &&
              addr.address.startsWith('192.168')) {
            setState(() {
              _localIP = addr.address; // Set the local IP address
            });
          }
        }
      }
    } catch (e) {
      log("Error fetching local IP: $e");
    }
  }

  Future<void> _discoverDevices() async {
    setState(() {
      _devices.clear();
      _isScanning = true;
    });

    final info = NetworkInfo();
    final ip = await info.getWifiIP();
    if (ip == null) {
      setState(() => _isScanning = false);
      return;
    }

    final subnet = ip.substring(0, ip.lastIndexOf('.'));

    const port = 8080;
    final futures = <Future>[];

    for (int i = 1; i < 255; i++) {
      final target = '$subnet.$i';
      futures.add(_pingIp(target, port));
    }

    await Future.wait(futures);
    setState(() => _isScanning = false);
  }

  Future<void> _pingIp(String ip, int port) async {
    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: Duration(milliseconds: 300),
      );

      // Send our name to the other device
      socket.write('NAME:${widget.name}\n');

      // Read the response to get their name
      final completer = Completer<String>();
      socket.listen(
        (data) {
          final response = String.fromCharCodes(data);
          if (response.startsWith('NAME:')) {
            completer.complete(response);
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete('');
          }
        },
      );

      final response = await completer.future;
      if (response.isNotEmpty) {
        final remoteName = response.substring(5).trim();
        if (_localIP != null && ip != _localIP) {
          setState(() {
            _devices[ip] = remoteName;
          });
        }
      }

      _openSockets.add(socket);
      socket.destroy();
    } catch (_) {}
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PingChat - ${widget.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _discoverDevices,
          ),
        ],
      ),
      body:
          _isScanning
              ? const Center(child: CircularProgressIndicator())
              : _devices.isEmpty
              ? const Center(child: Text('No devices found'))
              : ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final ip = _devices.keys.elementAt(index);
                  final name = _devices[ip]!;
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
              ),
    );
  }
}
