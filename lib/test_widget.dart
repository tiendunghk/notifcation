import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:notification/photo.dart';
import 'package:http/http.dart' as http;

class TestWidget extends StatefulWidget {
  static const routeName = '/test-widget';
  const TestWidget({Key? key}) : super(key: key);

  @override
  _TestWidgetState createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> {
  var init = false;
  late Photo photo;

  late Future<void> _getData;

  Future<void> _fetchData() async {
    final argument = ModalRoute.of(context)?.settings.arguments as String;

    var res = await http.get(
        Uri.parse('https://jsonplaceholder.typicode.com/photos/$argument'));

    if (res.statusCode == 200) {
      print('data: ${res.body}');
      var data = Photo.fromJson(json.decode(res.body));
      print(res.body);
      setState(() {
        photo = data;
      });
    }
  }

  @override
  void didChangeDependencies() {
    if (!init) {
      _getData = _fetchData();
      init = true;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Widget'),
      ),
      body: FutureBuilder(
          future: _getData,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            return Center(
              child: Column(
                children: [
                  Image.network(
                    photo.url,
                    fit: BoxFit.cover,
                  ),
                  Text(photo.title),
                ],
              ),
            );
          }),
    );
  }
}
