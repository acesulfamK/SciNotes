import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scribble/scribble.dart';
import 'package:value_notifier_tools/value_notifier_tools.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/rendering.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scribble with Lasso',
      theme: ThemeData.from(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple)),
      home: const HomePage(title: 'Scribble with Lasso'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ScribbleNotifier notifier;
  List<Offset> lassoPath = [];
  bool isLassoMode = false;
  GlobalKey repaintBoundaryKey = GlobalKey();

  @override
  void initState() {
    notifier = ScribbleNotifier();
    super.initState();
  }

  Future<void> _captureAndSavePng() async {
    try {
      print("Capture is started");
      RenderRepaintBoundary boundary = repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/captured_image.png';
        final file = File(filePath);
        await file.writeAsBytes(pngBytes);
        print('An image is saved to $filePath');
      }
    } catch (e) {
      print('エラーが発生しました: $e');
    }
  }
  
  Color _currentColor = Colors.black;

  void _togglePenColor() {
    setState(() {
      // Toggle between Colors.lightBlue and Colors.black
      _currentColor = _currentColor == Colors.lightBlue ? Colors.black : Colors.lightBlue;
      notifier.setColor(_currentColor);
    });
  }
  
  void _toggleLassoMode() {
    setState((){
      isLassoMode = !isLassoMode;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), // Reset icon
            tooltip: "Reset Whiteboard",
            onPressed: () {
              notifier.clear(); // Clears the whiteboard
            },
          ),
          IconButton(
            icon: Icon(Icons.brush, color: _currentColor),
            tooltip: "Light Blue Pen",
            onPressed: (){
              _togglePenColor();
              _toggleLassoMode();
            }
          ),
        ],
      ),
      body: RepaintBoundary(
        key: repaintBoundaryKey,
        child: GestureDetector(
          onPanStart: (details) {
            print("Pan started!!");
            if (isLassoMode) {
              setState(() {
                lassoPath = [details.localPosition];
              });
            }
          },
          onPanUpdate: (details) {
            if (isLassoMode) {
              setState(() {
                lassoPath.add(details.localPosition);
              });
            }
          },
          onPanEnd: (details) async {
            print("Pan ended!!");
            if (isLassoMode) {
              setState(() {
                lassoPath.add(lassoPath.first);
              });
              await _captureAndSavePng();
              setState(() {
                lassoPath.clear();
              });
            }
          },
          onTap: () => print("I was trapped!"),
          
          child: CustomPaint(
            painter: LassoPainter(lassoPath: lassoPath),
            child: Scribble(
              notifier: notifier,
              drawPen: true,
            ),
          ),
        ),
      ),
    );
  }
}

class LassoPainter extends CustomPainter {
  final List<Offset> lassoPath;

  LassoPainter({required this.lassoPath});

  @override
  void paint(Canvas canvas, Size size) {
    if (lassoPath.isNotEmpty) {
      final paint = Paint()
        ..color = Colors.lightBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      final path = Path()..addPolygon(lassoPath, true);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
