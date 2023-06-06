import 'dart:async';
import 'dart:io' show Directory, File, Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class Editor extends StatefulWidget {
  @override
  _EditorState createState() => _EditorState();
  
  final FlutterTts flutterTts;
  final int?       maximumLength;

  // Pass in the TTS object
  Editor(this.flutterTts, this.maximumLength);
}

enum TtsState { playing, stopped, paused, continued }

class _EditorState extends State<Editor> with AutomaticKeepAliveClientMixin<Editor> {

  String? _newVoiceText;
  TtsState ttsState = TtsState.stopped;

  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;
  get isPaused => ttsState == TtsState.paused;
  get isContinued => ttsState == TtsState.continued;

  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isWeb => kIsWeb;

  bool _exporting = false;

  // Initialise a scroll controller.
  final ScrollController _scrollController = ScrollController();

  @override
  initState() {
    super.initState();
    
    widget.flutterTts.setStartHandler(() {
      setState(() {
        print("Playing");
        ttsState = TtsState.playing;
      });
    });

    if (isAndroid) {
      widget.flutterTts.setInitHandler(() {
        setState(() {
          print("TTS Initialized");
        });
      });
    }

    widget.flutterTts.setCompletionHandler(() {
      setState(() {
        print("[INFO] Complete");
        ttsState = TtsState.stopped;
      });
    });

    widget.flutterTts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        ttsState = TtsState.stopped;
      });
    });

    widget.flutterTts.setPauseHandler(() {
      setState(() {
        print("Paused");
        ttsState = TtsState.paused;
      });
    });

    widget.flutterTts.setContinueHandler(() {
      setState(() {
        print("Continued");
        ttsState = TtsState.continued;
      });
    });

    widget.flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MaterialApp(
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          leading: Padding(padding: EdgeInsets.all(5), child: Image.asset("assets/icon_round.png")), //Icons.speaker_notes_outlined),
          title: Row(children: [Padding(padding: EdgeInsets.all(10), child:Icon(Icons.edit)), Text('Inserimento testo')]),
        ),
        body: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(child: _inputSection()),
                _btnSection(),
                _shareSection(context),
                Container(height: 50)
              ])
        )
    );
  }

  Widget _inputSection() {

    return Container(
      alignment: Alignment.topCenter, 	
      padding: EdgeInsets.all(10.0),
      child: Scrollbar(controller: _scrollController, child: 
        TextField(
          scrollController: _scrollController,
          decoration: InputDecoration(
            hintText: "Inserire il messaggio da leggere...",
            border: OutlineInputBorder()
          ),
          maxLength: widget.maximumLength ?? 0,
          maxLines : 9999,
          onChanged: (String value) {
            _onChange(value);
          },
        )
      ));
  }

  Widget _btnSection() {
    return Visibility(
      visible: !_exporting,
      child: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildButtonColumn(Colors.green, Colors.greenAccent, Icons.play_arrow,
                'PLAY', _speak),
            _buildButtonColumn(
                Colors.red, Colors.redAccent, Icons.stop, 'STOP', _stop),
            _buildButtonColumn(
                Colors.blue, Colors.blueAccent, Icons.pause, 'PAUSE', _pause, enabled: isPaused == false),
          ],
        ),
      ),
    );
  }

  Widget _shareSection(BuildContext context)
  {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Center(
            child: _exporting ? CircularProgressIndicator(value:null) :  TextButton(onPressed: () => _shareProcess(context), 
                        child: Text('Condividi'),
                        style: TextButton.styleFrom(                          
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blueAccent,                        
                        ),),
          ),
    );
  }

  
  void _onChange(String text) {
    setState(() {
      _newVoiceText = text;
    });
  }

  void _shareProcess(BuildContext context) async
  {

    setState(() {
      _exporting = true;
    });

    await _share(context);


    setState(() {
      _exporting = false;
    });


  } 

  Future _share(BuildContext context) async {
  
  
  final filename = "exported_file.wav";
  
  var directoryPath =
        "${(await getExternalStorageDirectory())!.path}/audio/";
    var directory = Directory(directoryPath);
    if (!await directory.exists()) {
      await directory.create();
      print('[INFO] Created the directory');
    }

    var path =
        "${(await getExternalStorageDirectory())!.path}/audio/$filename";
    print('[INFO] path: $path');
    var file = File(path);
    if (!await file.exists()) {
      await file.create();
      print('[INFO] Created the file');
    }

    var synth = await widget.flutterTts.synthesizeToFile(_newVoiceText!, "audio/$filename");
    if (synth == 1)
    {
      await Share.shareFiles([ path ]);
    }
  } 

  Future _speak() async {

    if (_newVoiceText != null) {
      if (_newVoiceText!.isNotEmpty) {
        await widget.flutterTts.speak(_newVoiceText!);
      }
    }
  }
  Future _stop() async {
    var result = await widget.flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  Future _pause() async {
    var result = await widget.flutterTts.pause();
    if (result == 1) setState(() => ttsState = TtsState.paused);
  }

  Column _buildButtonColumn(Color color, Color splashColor, IconData icon,
      String label, Function func, {bool enabled = true}) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
              icon: Icon(icon),
              color: color,
              splashColor: splashColor,
              onPressed: enabled ? () => func() : null),
          Container(
              margin: const EdgeInsets.only(top: 8.0),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w400,
                      color: color)))
        ]);
  }
  
  @override
  bool get wantKeepAlive { return true; }
}