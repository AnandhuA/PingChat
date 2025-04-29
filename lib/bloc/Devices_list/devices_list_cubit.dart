import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:network_info_plus/network_info_plus.dart';

part 'devices_list_state.dart';

class DevicesListCubit extends Cubit<DevicesListState> {
  DevicesListCubit() : super(DevicesListInitial());

  discoverDevices({required String name}) async {
    emit(DevicesListLoadingState());
    Map<String, String> devices = {};
    final info = NetworkInfo();
    final ip = await info.getWifiIP();
    final String? localIp = await _getLocalIP();

    if (ip == null) {
      return emit(DevicesListErrorState());
    }

    final subnet = ip.substring(0, ip.lastIndexOf('.'));
    const port = 8080;

    for (int i = 1; i < 255; i++) {
      final target = '$subnet.$i';

      _pingIp(ip: target, port: port, localIp: localIp, name: name).then((
        deviceName,
      ) {
        if (deviceName != null && target != localIp) {
          devices[target] = deviceName;
          emit(DevicesListSuccessState(devices: Map.from(devices)));
        }
      });
    }
  }
}

//--------- get devices list with names --------
Future<String?> _pingIp({
  required String ip,
  required int port,
  required String? localIp,
  required String name,
}) async {
  // log("ping");
  try {
    final socket = await Socket.connect(
      ip,
      port,
      timeout: Duration(milliseconds: 300),
    );
    socket.write('NAME:$name\n');
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
      if (localIp != null && ip != localIp) {
        log("--bloc--$remoteName");
        return remoteName;
      }
    }
    socket.destroy();
  } catch (e) {
    // log("error $e");
  }
  return null;
}

// -------------- get local ip ---------------
Future<String?> _getLocalIP() async {
  // log("got ip");
  try {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 &&
            !addr.isLoopback &&
            addr.address.startsWith('192.168')) {
          return addr.address; // Set the local IP address
        }
      }
    }
  } catch (e) {
    log("Error fetching local IP: $e");
  }
  return null;
}
