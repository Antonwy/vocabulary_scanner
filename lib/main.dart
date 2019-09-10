import 'dart:async';
import 'dart:io';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
// import 'package:mlkit/mlkit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';

import 'package:vocabulary_scanner/ListPage.dart';
import 'package:vocabulary_scanner/TextDetectionDecoration.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(title: 'Vocabulary Scanner'),
      theme: ThemeData.dark(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PermissionStatus _status;

  Future<File> imageFile;

  List<Translation> translationList = [];

  List<Rect> _rectList = [];

  @override
  void initState() {
    super.initState();
    PermissionHandler()
        .checkPermissionStatus(PermissionGroup.camera)
        .then(_updateStatus);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.help),
              onPressed: () {
                showAboutDialog(
                    context: context,
                    applicationName: "Vocabulary Scanner",
                    children: [
                      Text("""
To achieve the best results follow these three steps:
1. take a picture of the vocabulary list.
2. Check that the word and the translation is parallel.
3. Crop the picture, so that there are no other letters or numbers like the page number.
                    """)
                    ]);
              },
            )
          ],
        ),
        floatingActionButton: Visibility(
          visible: translationList.isNotEmpty,
          child: FloatingActionButton(
            child: Icon(Icons.navigate_next),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ListPage(translationList)));
            },
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              flex: 3,
              child: FutureBuilder(
                future: imageFile,
                builder: (context, snapshot) {
                  if (snapshot.hasData)
                    return Card(
                      child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: FutureBuilder(
                              future: _getImageSize(Image.file(snapshot.data)),
                              builder: (context, s) => s.hasData
                                  ? Container(
                                      child: Image.file(snapshot.data),
                                      foregroundDecoration:
                                          TextDetectionDecoration(
                                              orginalImageSize: s.data,
                                              rects: _rectList),
                                    )
                                  : Container())),
                      elevation: 7,
                    );
                  else
                    return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () async {
                            setState(() {
                              _rectList = [];
                            });
                            await _optionsDialogBox();
                          },
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.camera_alt),
                          ),
                        ));
                },
              ),
            ),
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  OutlineButton(
                    onPressed: () async {
                      setState(() {
                        _rectList = [];
                      });
                      await _optionsDialogBox();
                    },
                    child: Text('Select Image'),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Builder(builder: (context) {
                    return OutlineButton(
                      onPressed: () async {
                        if (imageFile != null) {
                          await imageFile;
                          // _detectText(context);
                          await _secondDetectionMethod(context);
                        } else {
                          Scaffold.of(context).showSnackBar(SnackBar(
                            content: Text(
                              "Please select an image!",
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Theme.of(context).primaryColor,
                            duration: Duration(seconds: 1),
                          ));
                        }
                      },
                      child: Text('Detect Text'),
                    );
                  }),
                ],
              ),
            )
          ],
        ));
  }

  Future<Size> _getImageSize(Image image) {
    Completer<Size> completer = new Completer<Size>();
    image.image.resolve(new ImageConfiguration()).addListener(
        ImageStreamListener((ImageInfo info, bool _) => completer.complete(
            Size(info.image.width.toDouble(), info.image.height.toDouble()))));
    return completer.future;
  }

  void _secondDetectionMethod(BuildContext context) async {
    print('DETECTING VOCABS');

    File img = await imageFile;

    final FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(img);
    final TextRecognizer textRecognizer =
        FirebaseVision.instance.textRecognizer();
    final VisionText visionText =
        await textRecognizer.processImage(visionImage);

    if (visionText.blocks.isEmpty) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("No text found...", style: TextStyle(color: Colors.white),),
        duration: Duration(seconds: 1),
        backgroundColor: Theme.of(context).primaryColor,
      ));
      return;
    }

    List<Rect> rectList = [];
    List<Word> wordList = [];

    for (TextBlock block in visionText.blocks) {
      String language = _getBestLanguage(block.recognizedLanguages);
      for (TextLine line in block.lines) {
        rectList.add(line.boundingBox);
        wordList.add(Word(
            word: line.text,
            x: line.boundingBox.left,
            y: line.boundingBox.top,
            language: language,
            heigth: line.boundingBox.height));
      }
    }

    translationList = _createTranslationList(wordList);

    setState(() {
      _rectList = rectList;
    });
  }

  String _getBestLanguage(List<RecognizedLanguage> list) {
    Map<String, int> firstLanguageCountMap = {};

    for (RecognizedLanguage language in list) {
      firstLanguageCountMap[language.languageCode] =
          firstLanguageCountMap[language.languageCode] == null
              ? 0
              : firstLanguageCountMap[language.languageCode] + 1;
    }

    int maxElement = firstLanguageCountMap.values.reduce(max);

    return firstLanguageCountMap.keys
        .toList()[firstLanguageCountMap.values.toList().indexOf(maxElement)];
  }

  _createTranslationList(List<Word> wordList) {
    List<Translation> list = [];

    String firstLang = wordList[0].language;

    List<Word> filteredWordList =
        wordList.where((Word w) => w.language == firstLang).toList();

    for (Word word in filteredWordList) {
      List<Word> nearestWords = wordList
          .where((label) =>
              word.y - 10 <= label.y &&
              label.y <= word.y + 10 &&
              label.language != firstLang)
          .toList();

      if (nearestWords.isNotEmpty) {
        Word translation = nearestWords[0];
        list.add(Translation(
          word: word.word,
          wordLanguage: word.language,
          translation: translation.word,
          translationLanguage: translation.language,
        ));
      }
    }

    return list;
  }

  Future<void> _optionsDialogBox() async {
    return await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Take Photo'),
                  onTap: _askPermission,
                ),
                ListTile(
                  leading: Icon(Icons.photo),
                  title: Text('From Gallery'),
                  onTap: imageSelectorGallery,
                ),
              ],
            ),
          );
        });
  }

  void _askPermission() {
    PermissionHandler()
        .requestPermissions([PermissionGroup.camera]).then(_onStatusRequested);
  }

  void _onStatusRequested(Map<PermissionGroup, PermissionStatus> value) {
    final status = value[PermissionGroup.camera];
    if (status == PermissionStatus.granted) {
      imageSelectorCamera();
    } else {
      _updateStatus(status);
    }
  }

  _updateStatus(PermissionStatus value) {
    if (value != _status) {
      setState(() {
        _status = value;
      });
    }
  }

  void imageSelectorCamera() async {
    Navigator.pop(context);
    var imageFile = await ImagePicker.pickImage(
      source: ImageSource.camera,
    );
  }

  void imageSelectorGallery() async {
    Navigator.pop(context);
    setState(() {
      imageFile = ImagePicker.pickImage(
        source: ImageSource.gallery,
      );
    });
  }
}

Future<Size> _getImageSize(Image image) {
  Completer<Size> completer = Completer<Size>();
  image.image.resolve(ImageConfiguration()).addListener(ImageStreamListener(
      (ImageInfo info, bool _) => completer.complete(
          Size(info.image.width.toDouble(), info.image.height.toDouble()))));
  return completer.future;
}

class Translation {
  String word,
      translation,
      wordLanguage,
      translationLanguage,
      wordTranslation,
      translatedTranslation;

  Translation(
      {this.word,
      this.translation,
      this.wordLanguage,
      this.translationLanguage,
      this.wordTranslation,
      this.translatedTranslation});

  void changeTranslation() {
    String oldWord = word, oldTranslation = translation;
    word = oldTranslation;
    translation = oldWord;
  }

  String toString() => "Word: $word, Translation: $translation";
}

class Word {
  String word, language;
  double y, x, heigth;

  Word({this.word, this.y, this.x, this.heigth, this.language});

  String toString() =>
      "Word: $word, y: $y, x: $x, heigth: $heigth, language: $language";
}
