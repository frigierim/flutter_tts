import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_tts_example/voice.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Configuration extends StatefulWidget {
  @override
  _ConfigurationState createState() => _ConfigurationState();
  
  final FlutterTts flutterTts;
  final Voice?      defaultVoice;
  final String?     defaultLangugage;
  final String?     defaultEngine;

  // Pass in the TTS object
  Configuration(this.flutterTts, this.defaultVoice, this.defaultLangugage, this.defaultEngine);
}

class _ConfigurationState extends State<Configuration>  with AutomaticKeepAliveClientMixin<Configuration>{
  
  static const double defaultVolume = 0.5;
  static const double defaultPitch = 1.0;
  static const double defaultRate = 0.5;
  
  static const double kMinVolume = 0.0;
  static const double kMaxVolume = 1.0;
  static const double kMinPitch = 0.5;
  static const double kMaxPitch = 2.0;
  static const double kMinRate = 0.0;
  static const double kMaxRate = 1.0;
  
  String? language;
  String? engine;
  Voice? voice;
  double volume = defaultVolume;
  double pitch = defaultPitch;
  double rate = defaultRate;
  
  bool isCurrentLanguageInstalled = false;

  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isWeb => kIsWeb;

  Future<dynamic> _getLanguages() async => await widget.flutterTts.getLanguages;

  Future<dynamic> _getEngines() async => await widget.flutterTts.getEngines;

  Future<dynamic> _getVoices() async => await widget.flutterTts.getVoices;

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  initState() {
    
    super.initState();
    language = widget.defaultLangugage;
    //voice = widget.defaultVoice;
    //engine = widget.defaultEngine;
  
    WidgetsBinding.instance.addPostFrameCallback((_){
      loadSettings();
    });
  } 


  Future<void> loadSettings() async {

    final prefs = await _prefs;
    language = (prefs.getString('language') ?? widget.defaultLangugage);
    engine = (prefs.getString('engine') ?? widget.defaultEngine);
    
    final voiceName    = (prefs.getString('voiceName'));
    final voiceLocale  = (prefs.getString('voiceLocale'));
    
    if (voiceName != null && voiceLocale != null)
      voice = Voice(voiceName, voiceLocale);
    else
      voice = widget.defaultVoice;
    
    volume = (prefs.getDouble('volume') ?? defaultVolume);
    pitch = (prefs.getDouble('pitch') ?? defaultPitch);
    rate = (prefs.getDouble('rate') ?? defaultRate);

    await widget.flutterTts.setVolume(volume);
    await widget.flutterTts.setPitch(pitch);
    await widget.flutterTts.setSpeechRate(rate);
 
    await widget.flutterTts.setEngine(engine!);
    widget.flutterTts.setLanguage(language!);
    widget.flutterTts.setVoice({
        "name": voice!.name,
        "locale": voice!.locale,
    });
 
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<DropdownMenuItem<String>> getEnginesDropDownMenuItems(dynamic engines) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in engines) {
      items.add(DropdownMenuItem(
          value: type as String?, child: Text(type as String)));
    }
    return items;
  }
  
  Future<void> saveEngine(String e) async 
  {
    final prefs = await _prefs;
    prefs.setString('engine', e);
  }

  void changedEnginesDropDownItem(String? selectedEngine) async {
    await widget.flutterTts.setEngine(selectedEngine!);
    setState(() {
      voice = null;
      language = null;
      engine = selectedEngine;
    });

    saveEngine(selectedEngine);
  }

  String countryCodeFlag(String country) {

    var countryCodeList = country.split("-");
    var countryCode = "";
    if (countryCodeList.length > 1)
      countryCode = countryCodeList[1];
    else
      countryCode = countryCodeList[0];

    var flag = countryCode.toUpperCase().replaceAllMapped(RegExp(r'[A-Z]'),
                  (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) + 127397));
    return flag;
  }

  List<DropdownMenuItem<String>> getLanguageDropDownMenuItems(
      dynamic languages) {
    var items = <DropdownMenuItem<String>>[];
    var sorted = languages as List;
    sorted.sort();

    for (dynamic type in sorted) {
      items.add(DropdownMenuItem(
          value: type as String?, child: Text(countryCodeFlag(type as String) + " " + Locale(type).toLanguageTag() )));
    }
    return items;
  }

  Future<void> saveLanguage(String l) async 
  {
    final prefs = await _prefs;
    prefs.setString('language', l);
  }

  void changedLanguageDropDownItem(String? selectedType) {
    setState(() {
      language = selectedType;
      voice = null;
      widget.flutterTts.setLanguage(language!);
      if (isAndroid) {
        widget.flutterTts
            .isLanguageInstalled(language!)
            .then((value) => isCurrentLanguageInstalled = (value as bool));
      }
    });
    saveLanguage(selectedType!);
  }

  List<DropdownMenuItem<Voice>> getVoiceDropDownMenuItems(
      dynamic voices) {
    var items = <DropdownMenuItem<Voice>>[];
    var later_items = <DropdownMenuItem<Voice>>[];
    for (dynamic type in voices) {

      var voiceName = type["name"] as String;
      var voiceLocale = type["locale"] as String;

      var v = Voice(voiceName, voiceLocale);
      if (v.locale == language)
      {
        items.add(DropdownMenuItem<Voice>(
                  value: v, child: Text(v.name)));
    
        if (voice == null || voice!.locale != voiceLocale)
            voice = v; 
      }
      else
      {
        later_items.add(DropdownMenuItem<Voice>(
                  value: v, child: Text(v.name)));
      }
    }

    items += later_items;
    return items;
  }

  Future<void> saveVoice(Voice v) async 
  {
    final prefs = await _prefs;
    prefs.setString('voiceName', v.name);
    prefs.setString('voiceLocale', v.locale);
  }

  void changedVoiceDropDownItem(Voice? selectedType) {
    setState(() {
      voice = selectedType;
      widget.flutterTts.setVoice({
        "name": voice!.name,
        "locale": voice!.locale,
      });
    });
    saveVoice(selectedType!);

  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MaterialApp(
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          leading: Padding(padding: EdgeInsets.all(5), child: Image.asset("assets/icon_round.png")), //Icons.speaker_notes_outlined),
          title: Row(children: [Padding(padding: EdgeInsets.all(10), child:Icon(Icons.settings_voice)), Text('Configurazione voce')]),
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: 
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Table(
            border: TableBorder(),
            columnWidths: const <int, TableColumnWidth>{
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: <TableRow>[
              
              // Invisible
              TableRow(children: [Visibility(visible: isAndroid, child: Text("Engine:")), _engineSection()]),
              
              TableRow(
                children: <Widget>[
                  Text("Lingua:"),
                  _futureBuilder()
                ]
              ),

              TableRow(
                children: <Widget>[
                  Text("Voce:"),
                  _voiceBuilder()
                ]
              ),

              TableRow(
                children: <Widget>[
                  Text("Volume:"),
                  _volume()
                ]
              ),

              TableRow(
                children: <Widget>[
                  Text("Tono:"),
                  _pitch()
                ]
              ),

              TableRow(
                children: <Widget>[
                  Text("Velocità:"),
                  _rate()
                ]
              )
            ]
          ),
        )
      ),
    ),
  ); 
  
  }

  Widget _engineSection() {
    if (isAndroid) {
      return FutureBuilder<dynamic>(
          future: _getEngines(),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.hasData) {
              return _enginesDropDownSection(snapshot.data);
            } else if (snapshot.hasError) {
              return Text('Error loading engines...');
            } else
              return CircularProgressIndicator();
          });
    } else
      return Container(width: 0, height: 0);
  }

  Widget _futureBuilder() => FutureBuilder<dynamic>(
      future: _getLanguages(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasData) {
          return _languageDropDownSection(snapshot.data);
        } else if (snapshot.hasError) {
          return Text('Errore nel caricamento delle lingue...');
        } else
          return CircularProgressIndicator();
      });

    Widget _voiceBuilder() => FutureBuilder<dynamic>(
      future: _getVoices(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasData) {
          return _voiceDropDownSection(snapshot.data);
        } else if (snapshot.hasError) {
          return Text('Errore nel caricamento delle voci...');
        } else
          return CircularProgressIndicator();
      });

  
  Widget _enginesDropDownSection(dynamic engines) => 
        Visibility(
          visible: isAndroid,
          child:
          Container(
          child: DropdownButton(
            value: engine,
            items: getEnginesDropDownMenuItems(engines),
            onChanged: changedEnginesDropDownItem,
          ),
        )
    );

  
  String?  getValidLanguageSelection(dynamic languages, String? language)
  {
    var list = languages as List<String?>;
    return list.firstWhere((element) => element == language, orElse: null);
  }

  
  Widget _languageDropDownSection(dynamic languages) => Container(
      padding: EdgeInsets.only(top: 10.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        DropdownButton(
          value: language, 
          //getValidLanguageSelection(languages, language),
          items: getLanguageDropDownMenuItems(languages),
          onChanged: changedLanguageDropDownItem,
        ),
        Visibility(
          visible: isAndroid && !isCurrentLanguageInstalled,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(Icons.warning_amber, color: Colors.amber),
          ),
        ),
      ]));


  Voice?  getValidVoice(dynamic voices, Voice? voice)
  {
    return voice;
    /*
    var list = voices as List<Map<String, String>>;
    var match = list.firstWhere((element) {
                                      var voiceName = element["name"] as String;
                                      var voiceLocale = element["locale"] as String;

                                      var v = Voice(voiceName, voiceLocale);
                                        return v == voice;
                                      },    
                                      orElse: null);
  
    Voice? v;
    if (match.isNotEmpty)
     v = Voice(match["name"] as String, match["locale"] as String);

    return v;
    */
  }


  Widget _voiceDropDownSection(dynamic voices) => Container(
      padding: EdgeInsets.only(top: 10.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        DropdownButton<Voice>(
          value: voice,
          items: getVoiceDropDownMenuItems(voices),
          onChanged: changedVoiceDropDownItem,
        ),
      ]));
  
  Widget _volume() {
    return Slider(
        value: volume,
        onChanged: (newVolume) async {
          await widget.flutterTts.setVolume(newVolume);
          final prefs = await _prefs;
          prefs.setDouble('volume', newVolume);
          
          setState(() {
            volume = newVolume;
          });
        },
        min: kMinVolume,
        max: kMaxVolume,
        divisions: 20,
        label: "$volume");
  }

  Widget _pitch() {
    return Slider(
      value: pitch,
      onChanged: (newPitch) async {
        await widget.flutterTts.setPitch(newPitch);
        final prefs = await _prefs;
        prefs.setDouble('pitch', newPitch);
        setState(() {
          pitch = newPitch;
        });
      },
      min: kMinPitch,
      max: kMaxPitch,
      divisions: 15,
      label: "$pitch",
    );
  }

  Widget _rate() {
    return Slider(
      value: rate,
      onChanged: (newRate) async {
        await widget.flutterTts.setSpeechRate(newRate);
        final prefs = await _prefs;
        prefs.setDouble('rate', newRate);
        setState(() {
          rate = newRate;
        });
      },
      min: kMinRate,
      max: kMaxRate,
      divisions: 10,
      label: "$rate",
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}


