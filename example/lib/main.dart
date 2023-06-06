import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_tts_example/configuration.dart';
import 'package:flutter_tts_example/editor.dart';
import 'package:flutter_tts_example/voice.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'TTS Demo',
      home: new MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// An indicator showing the currently selected page of a PageController
class DotsIndicator extends AnimatedWidget {
  DotsIndicator(
    this.controller,
    this.itemCount,
    this.onPageSelected,
    { this.color: Colors.white }
  ) : super(listenable: controller);

  /// The PageController that this DotsIndicator is representing.
  final PageController controller;

  /// The number of items managed by the PageController
  final int itemCount;

  /// Called when a dot is tapped
  final ValueChanged<int> onPageSelected;

  /// The color of the dots.
  ///
  /// Defaults to `Colors.white`.
  final Color color;

  // The base size of the dots
  static const double _kDotSize = 20.0;

  // The increase in the size of the selected dot
  static const double _kMaxZoom = 2.0;

  // The distance between the center of each dot
  static const double _kDotSpacing = 60.0;

  Widget _buildDot(int index) {

    final icons = [ Icons.settings_voice, Icons.edit];
    var selectedness = Curves.easeOut.transform(
      max(
        0.0,
        1.0 - ((controller.page ?? controller.initialPage) - index).abs(),
      ),
    );
    var zoom = 1.0 + (_kMaxZoom - 1.0) * selectedness;
    return new Container(
      width: _kDotSpacing,
      padding: EdgeInsets.zero,
      child: new Center(
        child: new Container(
            width: _kDotSize * zoom,
            height: _kDotSize * _kMaxZoom,
            padding: EdgeInsets.zero,
            child: new InkWell(
              child: Icon( icons[index], size: _kDotSize * zoom, color: color),
              onTap: () => onPageSelected(index),
            ),
          ),
        ),
    );
  }

  Widget build(BuildContext context) {
    return new Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: new List<Widget>.generate(itemCount, _buildDot),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State createState() => new MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {

  late FlutterTts flutterTts;
  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isWeb => kIsWeb;
    
  String? defaultLanguage;  
  Voice?  defaultVoice;
  String? defaultEngine;
  int?    _inputLength;

  final _controller = new PageController();

  static const _kDuration = const Duration(milliseconds: 300);

  static const _kCurve = Curves.ease;

  final _kArrowColor = Colors.black.withOpacity(0.8);

  final List<Widget> _pages = <Widget>[];

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      initTts();
    });
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

  initTts() async {
    flutterTts = FlutterTts();

    _setAwaitOptions();

    if (isAndroid) {
      await _getDefaultEngine();
      await _getDefaultVoice();
      await _getMaximumLength();
    }

    _pages.add(new ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: new Configuration(flutterTts, defaultVoice, defaultLanguage, defaultEngine)),
      );

    _pages.add(new ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: new Editor(flutterTts, _inputLength)),
      );

    await flutterTts.awaitSynthCompletion(true);
    
    // Refresh layout
    setState(() {}); 
  }

  Future _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      defaultEngine = engine as String;
    }
  }

  Future _getDefaultVoice() async {
    var localvoice = await flutterTts.getDefaultVoice;
    if (localvoice != null) {
      defaultVoice = Voice(localvoice["name"] as String, localvoice["locale"] as String);
      defaultLanguage = defaultVoice!.locale;
    }
  }

  Future _getMaximumLength() async 
  {
    _inputLength = await flutterTts.getMaxSpeechInputLength;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new IconTheme(
        data: new IconThemeData(color: _kArrowColor),
        child: 
          Stack(
          children: <Widget>[
            PageView.builder(
              physics: new AlwaysScrollableScrollPhysics(),
              controller: _controller,
              itemBuilder: (BuildContext context, int index) {
                if (_pages.length > 0)
                  return _pages[index % _pages.length];
                
                return Center(child: CircularProgressIndicator(value: null));
              },
              itemCount: _pages.length,
            ),
            Positioned(
              bottom: 0.0,
              left: 0.0,
              right: 0.0,
              child: new 
              Container(
                color: Colors.grey[800]!.withOpacity(0.5),
                padding: const EdgeInsets.all(10.0),
                child: new Center(
                  child: new DotsIndicator(
                      _controller,
                      _pages.length,
                      (int page) {
                      _controller.animateToPage(
                        page,
                        duration: _kDuration,
                        curve: _kCurve,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
