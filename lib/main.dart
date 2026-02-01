import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(
    const MaterialApp(
      home: DrawingReceiver(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class DrawingPoint {
  final Offset offset;
  final Paint paint;
  DrawingPoint(this.offset, this.paint);
}

class DrawingReceiver extends StatefulWidget {
  const DrawingReceiver({super.key});

  @override
  State<DrawingReceiver> createState() => _DrawingReceiverState();
}

class _DrawingReceiverState extends State<DrawingReceiver> {
  // VERVANG DIT IP door het IP van je laptop (bijv. ws://192.168.1.15:8765)
  // Als je de python server op DEZELFDE laptop draait, is localhost prima.
  late WebSocketChannel channel;
  List<DrawingPoint?> allPoints = [];

  @override
  void initState() {
    super.initState();
    try {
      channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8765'));
      _listenToWebSocket();
    } catch (e) {
      print("Kon niet verbinden: $e");
    }
  }

  void _listenToWebSocket() {
    channel.stream.listen((message) {
      final data = jsonDecode(message);

      if (data['type'] == 'stroke_batch') {
        final List points = data['points'];
        setState(() {
          for (var p in points) {
            allPoints.add(
              DrawingPoint(
                Offset(p['x'].toDouble(), p['y'].toDouble()),
                Paint()
                  ..color = _parseHexColor(p['color'])
                  ..strokeCap = StrokeCap.round
                  ..strokeWidth = p['size'].toDouble(),
              ),
            );
          }
        });
      } else if (data['type'] == 'end') {
        setState(() {
          allPoints.add(null);
        });
      } else if (data['type'] == 'clear') {
        setState(() {
          allPoints.clear();
        });
      }
    }, onError: (error) => print("WS Error: $error"));
  }

  Color _parseHexColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Receiver Running")),
      body: CustomPaint(painter: DrawingPainter(allPoints), child: Container()),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> points;
  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(
          points[i]!.offset,
          points[i + 1]!.offset,
          points[i]!.paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
