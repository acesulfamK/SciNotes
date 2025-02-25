import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scribble/scribble.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ScribbleScreen(),
    );
  }
}

class ScribbleScreen extends StatefulWidget {
  @override
  _ScribbleScreenState createState() => _ScribbleScreenState();
}

class CustomScribbleNotifier extends ScribbleNotifier {
  bool isLassoMode = false;
  
  bool isPointInsidePolygon(Point testPoint, List<Point> polygon) {
    int crossings = 0;
    for (int i = 0; i < polygon.length - 1; i++) {
      Point p1 = polygon[i];
      Point p2 = polygon[i + 1]; // Loop back to start

      // Ensure p1.y < p2.y for consistent direction
      if (p1.y > p2.y) {
        Point temp = p1;
        p1 = p2;
        p2 = temp;
      }

      // Check if testPoint.y is within y bounds of the segment
      if (testPoint.y > p1.y && testPoint.y <= p2.y) {
        // Find x intersection of the segment with the horizontal ray
        double xIntersection =
            p1.x + (testPoint.y - p1.y) * (p2.x - p1.x) / (p2.y - p1.y);

        if (xIntersection > testPoint.x) {
          crossings++;
        }
      }
    }
    return crossings % 2 == 1; // Odd = Inside, Even = Outside
  }

  bool isLineIntersectingLasso(SketchLine line, SketchLine lassoLine) {
    if (lassoLine.points.length < 3) return false; // A valid polygon needs at least 3 points
  
    // Ensure the lasso forms a closed loop by appending the first point at the end
    List<Point> lassoPolygon = List.from(lassoLine.points);
    if (lassoPolygon.first != lassoPolygon.last) {
      lassoPolygon.add(lassoPolygon.first);
    }
  
    // Check if any point in `line.points` is inside the polygon
    for (Point p in line.points) {
      if (isPointInsidePolygon(p, lassoPolygon)) {
        return true; // At least one point is inside
      }
    }
    return false;
  }


  
  void removeLastStroke() {
    if (value.sketch.lines.isNotEmpty) {
      final updatedLines = List<SketchLine>.from(value.sketch.lines);
      updatedLines.removeLast(); 
      value = value.copyWith(
        sketch: Sketch(lines: updatedLines),
      );
      notifyListeners(); 
    }
  }
  
  
  void changeStrokeColor(Color newColor) {
    if (value.sketch.lines.isNotEmpty) {
      final lassoLine = value.sketch.lines.last;
      final updatedLines = value.sketch.lines.map((line) {
        if (isLineIntersectingLasso(line, lassoLine)){
          print("Line intersects with lasso!");
          return SketchLine(
            points: line.points,
            color: newColor.value,
            width: line.width
          );
        } else {
          print("Line do not intersects with lasso!");
          return line;
        }
      }).toList();

      // ✅ Update the state with the modified sketch
      value = value.copyWith(
        sketch: Sketch(lines: updatedLines),
      );
      notifyListeners(); // ✅ Ensure UI updates
    }
  }
  

  @override
  void onPointerUp(PointerUpEvent event) {
    super.onPointerUp(event); // Call the original function
    print("Pen lifted! Executing custom instruction...");
    _handlePenLifted();
  }

  void _handlePenLifted() async {
    // Add any logic here (e.g., saving the stroke, updating UI)
    if (isLassoMode) {
      changeStrokeColor(Colors.red);
  
      // Collect lines that intersect with the lasso
      final lassoLine = value.sketch.lines.last;
      final intersectingLines = value.sketch.lines.sublist(0, value.sketch.lines.length - 1).where((line) {
        return isLineIntersectingLasso(line, lassoLine);
      }).toList();
  
      // Convert intersecting lines to JSON
      final jsonString = jsonEncode({
        'lines': intersectingLines.map((line) => line.toJson()).toList(),
      });
  
      // Save JSON to file
      try {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/lasso_intersecting_lines.json';
        final file = File(filePath);
        await file.writeAsString(jsonString);
        print("Intersecting lines saved: $filePath");
      } catch (e) {
        print("Error saving intersecting lines: $e");
      }
  
      removeLastStroke();
    }
    print("Custom logic executed after pen lift.");
  }
}

class _ScribbleScreenState extends State<ScribbleScreen> {
  late CustomScribbleNotifier _scribbleNotifier;
  Color _currentColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _scribbleNotifier = CustomScribbleNotifier();
    _scribbleNotifier.isLassoMode = false;
    _currentColor = Colors.black;
  }

  @override
  void dispose() {
    _scribbleNotifier.dispose();
    super.dispose();
  }

  /// **筆跡データをJSONファイルに保存**
  Future<void> saveSketchToFile(CustomScribbleNotifier notifier) async {
    try {
      // SketchデータをJSON文字列に変換
      final jsonString = jsonEncode(notifier.currentSketch.toJson());

      // アプリのドキュメントディレクトリを取得
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/scribble_sketch.json';


      // ファイルに書き込み
      final file = File(filePath);
      await file.writeAsString(jsonString);
      

      print("保存完了: $filePath");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("筆跡データを保存しました！")),
      );
    } catch (e) {
      print("エラー: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("保存に失敗しました！")),
      );
    }
  }
  

  void _togglePenColor() {
    setState(() {
      _currentColor = _currentColor == Colors.lightBlue ? Colors.black : Colors.lightBlue;
      _scribbleNotifier.setColor(_currentColor);
    });
  }
  
  void _toggleLassoMode() {
    setState(() {
      _scribbleNotifier.isLassoMode = !_scribbleNotifier.isLassoMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scribble Notepad"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), // Reset icon
            tooltip: "Reset Whiteboard",
            onPressed: () {
              _scribbleNotifier.clear(); // Clears the whiteboard
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
        ]
      ),
      body: Column(
        children: [
          Expanded(
            child: Scribble(
              notifier: _scribbleNotifier,
              drawPen: true, // 描画モードを有効化
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  _scribbleNotifier.clear();
                },
                child: const Text("クリア"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await saveSketchToFile(_scribbleNotifier);
                },
                child: const Text("保存"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
