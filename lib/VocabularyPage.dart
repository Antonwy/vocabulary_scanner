import 'package:flutter/material.dart';
import 'package:vocabulary_scanner/LanguageNames.dart';

import 'main.dart';

class VocabularyPage extends StatefulWidget {
  Translation translation;
  Function(Translation translation) onChange;
  Function() onDelete;

  VocabularyPage({this.translation, this.onChange, this.onDelete});

  @override
  _VocabularyPageState createState() => _VocabularyPageState();
}

class _VocabularyPageState extends State<VocabularyPage> {
  TextEditingController _firstController = TextEditingController(),
      _secondController = TextEditingController();
  PageController _pageController = PageController(viewportFraction: .7);

  bool _edit = false;

  @override
  Widget build(BuildContext context) {
    Translation translation = widget.translation;

    return Scaffold(
      appBar: AppBar(
        title: Text("Vocabulary"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            _saveAndBack(context);
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: PageView(
                  controller: _pageController,
                  children: <Widget>[
                    _createWord(
                        lang: translation.wordLanguage,
                        word: translation.word,
                        secWord: translation.wordTranslation ?? "",
                        controller: _firstController),
                    _createWord(
                        lang: translation.translationLanguage,
                        word: translation.translation,
                        secWord: translation.translatedTranslation ?? "",
                        controller: _secondController,
                        translation: true),
                  ],
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  IconButton(
                    icon: Icon(_edit ? Icons.done : Icons.edit),
                    onPressed: () {
                      setState(() {
                        _edit = !_edit;
                      });
                    },
                  ),
                  IconButton(
                    color: Theme.of(context).accentColor,
                    icon: Icon(Icons.save),
                    onPressed: () {
                      _saveAndBack(context);
                    },
                  ),
                  IconButton(
                    color: Colors.red,
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      widget.onDelete();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              )
            ],
          ),
        ),
      ),
    );
  }

  _saveAndBack(BuildContext context) {
    widget.onChange(widget.translation);
    Navigator.pop(context);
  }

  Widget _createWord(
      {String lang,
      String word,
      String secWord,
      TextEditingController controller,
      bool translation = false}) {
    controller.text = word;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Card(
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: 200),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    LanguageNames.names[lang],
                    style: TextStyle(fontWeight: FontWeight.w400, fontSize: 15),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  LayoutBuilder(builder: (context, constraints) {
                    return ConstrainedBox(
                        constraints: constraints,
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: Duration(milliseconds: 250),
                            child: _edit
                                ? TextField(
                                    controller: controller,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w600),
                                    onChanged: (String text) {
                                      if (translation)
                                        widget.translation.translation = text;
                                      else
                                        widget.translation.word = text;
                                    },
                                  )
                                : Text(
                                    word,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ));
                  }),
                  SizedBox(
                    height: 10,
                  ),
                  Text(secWord,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                          fontWeight: FontWeight.w300)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
