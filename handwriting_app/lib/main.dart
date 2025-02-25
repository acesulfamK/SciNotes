import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DrawingScreen(),
    );
  }
}

class DrawingScreen extends StatefulWidget {
  @override
  _DrawingScreenState createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  List<List<Offset>> strokes = []; // 全ての線のリスト
  List<Offset> currentStroke = []; // 現在の線のポイントリスト

  void _startDrawing(DragStartDetails details) {
    setState(() {
      currentStroke = [details.localPosition]; // 新しい線を開始
    });
  }

  void _updateDrawing(DragUpdateDetails details) {
    setState(() {
      currentStroke.add(details.localPosition); // ドラッグ中に線を追加
    });
  }

  void _endDrawing(DragEndDetails details) {
    setState(() {
      strokes.add(currentStroke); // 完成した線をリストに保存
      currentStroke = []; // 一時リストをクリア
    });
  }

  void _clearCanvas() {
    setState(() {
      strokes.clear(); // 全ての線を削除
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("お絵描きツール"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearCanvas,
            tooltip: "キャンバスをクリア",
          ),
        ],
      ),
      body: GestureDetector(
        onPanStart: _startDrawing,
        onPanUpdate: _updateDrawing,
        onPanEnd: _endDrawing,
        child: CustomPaint(
          size: Size.infinite,
          painter: DrawingPainter(strokes),
        ),
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;

  DrawingPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var stroke in strokes) {
      if (stroke.length > 1) {
        for (int i = 0; i < stroke.length - 1; i++) {
          canvas.drawLine(stroke[i], stroke[i + 1], paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
