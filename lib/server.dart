import 'dart:developer';
import 'dart:io';

class Server {
  ServerSocket? _serverSocket;
  final List<Socket> _clients = [];
  String? _name;

  Function(String message)? onMessageReceived; // for active screen
  Function(String ip, String message)?
  onGlobalMessageReceived; // new global handler

  void setName(String name) {
    _name = name;
  }

  Future<void> startServer() async {
    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 8080);
      log('Server started on port 8080');

      _serverSocket!.listen((Socket socket) {
        final remoteIp = socket.remoteAddress.address;
        log('Connection from $remoteIp');
        _clients.add(socket);

        socket.listen(
          (List<int> data) {
            final message = String.fromCharCodes(data).trim();
            log('Received message: $message');

            if (message.startsWith('NAME:')) {
              if (_name != null) {
                socket.write('NAME:$_name\n');
              }
              return;
            }

            _broadcastMessage(message, socket);

            // Send to ChatScreen
            if (onMessageReceived != null) {
              onMessageReceived!(message);
            }

            // Send to global handler
            if (onGlobalMessageReceived != null) {
              onGlobalMessageReceived!(remoteIp, message);
            }
          },
          onError: (error) {
            log("Error receiving message: $error");
          },
          onDone: () {
            log("Connection closed with $remoteIp");
            _clients.remove(socket);
            socket.close();
          },
        );
      });
    } catch (e) {
      log("Error starting server: $e");
    }
  }

  void _broadcastMessage(String message, Socket sender) {
    for (var client in _clients) {
      if (client != sender) {
        client.write('$message\n');
      }
    }
  }

  void stopServer() {
    _serverSocket?.close();
    for (var client in _clients) {
      client.close();
    }
    _clients.clear();
    log('Server stopped.');
  }
}
