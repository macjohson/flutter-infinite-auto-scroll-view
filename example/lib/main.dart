import 'package:flutter/material.dart';
import 'package:infinite_auto_scroll_view/infinite_auto_scroll_view.dart';
import "dart:math";

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  late final InfiniteAutoScrollController<String> _controller =
      InfiniteAutoScrollController(
          vsync: this,
          perItemDuration: const Duration(seconds: 1),
          itemExtend: 32,
          itemBuild: (item,active, index) {
            return Container(
              height: 32,
              child: Text(item, style: TextStyle(color: active ? Colors.redAccent : Colors.black),),
            );
          });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 220,
                  height: 400,
                  child: InfiniteAutoScrollView(infiniteAutoScrollController: _controller,),
                ),
              )
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                TextButton(onPressed: (){
                  _controller.pause();
                }, child: Text("pause")),
                TextButton(onPressed: (){
                  _controller.play();
                }, child: Text("play")),
                TextButton(onPressed: (){
                  _controller.next();
                }, child: Text("next")),
                TextButton(onPressed: (){
                  _controller.pre();
                }, child: Text("pre")),
                TextButton(onPressed: (){
                  _controller.pre(cursor: true);
                }, child: Text("move pre")),
                TextButton(onPressed: (){
                  _controller.next(cursor: true);
                }, child: Text("move next"))
              ],
            ),
            SizedBox(height: 70,)
          ]
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: (){
            _controller.setData(List.generate(Random().nextInt(50), (index) => "这是第$index条数据"));
          },
        ),
      ),
    );
  }
}
