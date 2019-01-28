import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: SearchScreen(title: 'Поиск книг'),
    );
  }
}

class SearchScreen extends StatefulWidget {
  SearchScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  State<StatefulWidget> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Book> _items = List();
  bool _isLoading = false;

  final subject = PublishSubject<String>();

  void _textChanged(String text) {
    if (text.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      _clearList();
      return;
    }
    setState(() {
      _isLoading = true;
    });
    _clearList();
    http
        .get("https://www.googleapis.com/books/v1/volumes/s1gVAAAAYAAJ")
        .then((response) => response.body)
        .then(json.decode)
        .then((map) => map["volumeInfo"])
        .then((list) {
          _onNext(list);
        })
        .catchError(_onError)
        .then((e) {
          setState(() {
            _isLoading = false;
          });
        });
  }

  void _clearList() {
    setState(() {
      _items.clear();
    });
  }

  void _onNext(dynamic book) {
    setState(() {
      _items.add(Book(book["title"], book["imageLinks"]["thumbnail"]));
    });
  }

  void _onError(dynamic error) {
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    subject.stream.debounce(Duration(milliseconds: 600)).listen(_textChanged);
  }

  @override
  void dispose() {
    super.dispose();
    subject.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Container(
        padding: EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 0.0)),
                  border: OutlineInputBorder(),
                  labelText: "Найти книгу",
                  labelStyle: TextStyle(color: Colors.black)),
              onChanged: (string) => subject.add(string),
            ),
            Container(
              padding: EdgeInsets.all(8.0),
              child: _isLoading ? CircularProgressIndicator() : Container(),
            ),
            Flexible(
              child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Row(
                          children: <Widget>[
                            _items[index].url != null
                                ? Image.network(_items[index].url)
                                : Container(),
                            Flexible(
                              child: Text(
                                _items[index].title,
                                maxLines: 10,
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  }),
            )
          ],
        ),
      ),
    );
  }
}

class Book {
  String title, url;

  Book(String title, String url) {
    this.title = title;
    this.url = url;
  }
}
