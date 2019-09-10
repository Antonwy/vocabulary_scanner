import 'dart:io';
import 'package:csv/csv.dart';
import 'package:firebase_mlkit_language/firebase_mlkit_language.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vocabulary_scanner/LanguageNames.dart';
import 'package:vocabulary_scanner/VocabularyPage.dart';
import 'package:vocabulary_scanner/main.dart';
import 'package:wc_flutter_share/wc_flutter_share.dart';

class ListPage extends StatefulWidget {
  List<Translation> list;

  ListPage(this.list);

  @override
  _ListPageState createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  String _boxName = "", _language1 = "", _language2 = "";

  final LanguageIdentifier languageIdentifier =
      FirebaseLanguage.instance.languageIdentifier();

  Future<LanguageTranslator> translatorOne;
  Future<LanguageTranslator> translatorTwo;

  String firstLanguage;
  String secondLanguage;

  TextEditingController _firstLanguageController = TextEditingController(),
      _secondLanguageController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getLanguages();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _firstLanguageController.dispose();
    _secondLanguageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Vocabulary List"),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.file_download),
        onPressed: () {
          _showDownloadDialog(context);
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    LanguageNames.names[firstLanguage] ?? "",
                    style: TextStyle(fontSize: 20),
                  ),
                  Text(
                    LanguageNames.names[secondLanguage] ?? "",
                    style: TextStyle(fontSize: 20),
                  )
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.list.length,
                itemBuilder: (context, i) {
                  Translation translation = widget.list[i];
                  return Row(
                    children: <Widget>[
                      Expanded(
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              _openVocabularyPage(translation);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: FutureBuilder<LanguageTranslator>(
                                  future: translatorTwo,
                                  builder: (context, data) {
                                    LanguageTranslator langTrans = data.data;
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          translation.word,
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        data.hasData
                                            ? FutureBuilder<String>(
                                                future: langTrans.processText(
                                                    translation.translation),
                                                builder: (context, snapshot) {
                                                  if (snapshot.hasData) {
                                                    translation
                                                            .wordTranslation =
                                                        snapshot.data;
                                                    return Text(
                                                      snapshot.data,
                                                      style: TextStyle(
                                                          color:
                                                              Colors.white60),
                                                    );
                                                  } else {
                                                    return Container();
                                                  }
                                                })
                                            : Container()
                                      ],
                                    );
                                  }),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.compare_arrows),
                        onPressed: () {
                          setState(() {
                            translation.changeTranslation();
                          });
                        },
                      ),
                      Expanded(
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              _openVocabularyPage(translation);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: FutureBuilder<LanguageTranslator>(
                                  future: translatorOne,
                                  builder: (context, data) {
                                    LanguageTranslator langTrans = data.data;
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          translation.translation,
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        data.hasData
                                            ? FutureBuilder<String>(
                                                future: langTrans.processText(
                                                    translation.word),
                                                builder: (context, snapshot) {
                                                  if (snapshot.hasData) {
                                                    translation
                                                            .translatedTranslation =
                                                        snapshot.data;
                                                    return Text(
                                                      snapshot.data,
                                                      style: TextStyle(
                                                          color:
                                                              Colors.white60),
                                                    );
                                                  } else {
                                                    return Container();
                                                  }
                                                })
                                            : Container()
                                      ],
                                    );
                                  }),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  _openVocabularyPage(Translation translation) {
    Navigator.push(
        context,
        MaterialPageRoute(
            maintainState: true,
            builder: (context) => VocabularyPage(
                  translation: translation,
                  onChange: (Translation t) {
                    setState(() {
                      widget.list[widget.list.indexOf(translation)] = t;
                    });
                  },
                  onDelete: () {
                    setState(() {
                      widget.list.removeWhere((trans) => trans == translation);
                    });
                  },
                )));
  }

  _getLanguages() async {
    print('DETECTING LANGUAGES');

    setState(() {
      firstLanguage = widget.list[0].wordLanguage;
      secondLanguage = widget.list[0].translationLanguage;
    });

    // await _downloadLanguage(firstLanguage);
    // await _downloadLanguage(secondLanguage);

    // translatorOne = Future.value(FirebaseLanguage.instance
    //     .languageTranslator(firstLanguage, secondLanguage));
    // translatorTwo = Future.value(FirebaseLanguage.instance
    //     .languageTranslator(secondLanguage, firstLanguage));
  }

  Future<String> _downloadLanguage(String lang) async {
    print('DOWNLOADING $lang');
    return await FirebaseLanguage.instance.modelManager().downloadModel(lang);
  }

  _showDownloadDialog(context) {
    _firstLanguageController.text = LanguageNames.names[firstLanguage];
    _secondLanguageController.text = LanguageNames.names[secondLanguage];

    _language1 = _firstLanguageController.text;
    _language2 = _secondLanguageController.text;

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Save as CSV"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  decoration: InputDecoration(hintText: "Boxname"),
                  onChanged: (text) {
                    _boxName = text;
                  },
                ),
                SizedBox(
                  height: 10,
                ),
                TextField(
                  controller: _firstLanguageController,
                  decoration: InputDecoration(hintText: "Language 1"),
                  onChanged: (text) {
                    _language1 = text;
                  },
                ),
                SizedBox(
                  height: 10,
                ),
                TextField(
                  controller: _secondLanguageController,
                  decoration: InputDecoration(hintText: "Language 2"),
                  onChanged: (text) {
                    _language2 = text;
                  },
                ),
              ],
            ),
            actions: <Widget>[
              FlatButton(
                child: Text(
                  "Cancel",
                ),
                textColor: Colors.red,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              FlatButton(
                child: Text("Save"),
                onPressed: () {
                  if (_boxName.isEmpty ||
                      _language1.isEmpty ||
                      _language2.isEmpty) return;
                  _createCVS(context);
                },
              ),
            ],
          );
        });
  }

  _createCVS(context) async {
    print('BoxName: $_boxName, Language1: $_language1, Language2: $_language2');

    List<List<String>> rowsList = [];

    for (var i = 0; i < widget.list.length + 4; i++) {
      List<String> columnList = [];
      for (var i2 = 0; i2 < 3; i2++) {
        String toAdd = "";
        if (i == 1 && i2 == 1)
          toAdd = _boxName;
        else if (i == 3 && i2 == 1)
          toAdd = _language1;
        else if (i == 3 && i2 == 2)
          toAdd = _language2;
        else if (i > 3) {
          if (i2 == 1)
            toAdd = widget.list[i - 4].word;
          else if (i2 == 2) toAdd = widget.list[i - 4].translation;
        }
        columnList.add(toAdd);
      }
      rowsList.add(columnList);
    }

    String csv = ListToCsvConverter().convert(rowsList);

    final dir = await getApplicationDocumentsDirectory();

    File f = File("${dir.path}/$_boxName.csv");

    f.writeAsString(csv);

    print(f.path);

    List<int> bytes = await f.readAsBytes();

    // Share.file("Vocabulary List", "$_boxName.csv", bytes, '*/*');

    WcFlutterShare.share(
      sharePopupTitle: 'Vocabulary List',  
    fileName: '$_boxName.csv',  
    mimeType: 'text/csv',  
    bytesOfFile: bytes
    );

    Navigator.pop(context);
  }
}
