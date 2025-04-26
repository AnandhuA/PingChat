import 'dart:developer';
import 'dart:io';

class Server {
  ServerSocket? _serverSocket;
  final List<Socket> _clients = [];

  Function(String)? onMessageReceived; // <-- ADD THIS

  Future<void> startServer() async {
    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 8080);
      log('Server started on port 8080');

      _serverSocket!.listen((Socket socket) {
        log('Connection from ${socket.remoteAddress.address}');
        _clients.add(socket);

        socket.listen(
          (List<int> data) {
            String message = String.fromCharCodes(data).trim();
            log('Received message: $message');
            _broadcastMessage(message, socket);
            if (onMessageReceived != null) {
              onMessageReceived!(message);
            } else {
              log("null----");
            }
          },
          onError: (error) {
            log("Error receiving message: $error");
          },
          onDone: () {
            log("Connection closed with ${socket.remoteAddress.address}");
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
