import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:ping_chat/main.dart';
import 'package:ping_chat/screen/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _devices = [];
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
      _openSockets.add(socket);
      socket.destroy();
      if (_localIP != null && ip != _localIP) {
        setState(() {
          _devices.add(ip);
        });
      }
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
        title: const Text('PingChat'),
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
                  return ListTile(
                    leading: const Icon(Icons.device_hub),
                    title: Text(_devices[index]),
                    onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ChatScreen(
                                peerIP: _devices[index],
                                server: server,
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
