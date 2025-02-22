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

class _ScribbleScreenState extends State<ScribbleScreen> {
  late ScribbleNotifier _scribbleNotifier;

  @override
  void initState() {
    super.initState();
    _scribbleNotifier = ScribbleNotifier();
  }

  @override
  void dispose() {
    _scribbleNotifier.dispose();
    super.dispose();
  }

  /// **筆跡データをJSONファイルに保存**
  Future<void> saveSketchToFile(ScribbleNotifier notifier) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scribble Notepad")),
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
