import 'dart:async';
import 'dart:io';

import 'package:lua_dardo/lua.dart';

void main(List<String> args) async {
  print("Starting");
  final chunk = await File("example/async_example.lua").readAsString();

  await LuaWorker(
    chunk: chunk,
    data: {"input": ""},
  ).run();
}

class LuaWorker {
  late final LuaState ls;
  final String chunk;
  final Map<String, dynamic> data;

  final _ready = Completer();

  LuaWorker({required this.chunk, required this.data}) {
    ls = LuaState.newState();

    ls.openLibs().then((value) {
      ls.register('sleep', luaSleep);
      ls.register('dprint', luaPrint);

      _ready.complete();
    }); // allow all std Lua libs
  }

  Future<void> run() async {
    await _ready.future;

    for (final d in data.keys) {
      final val = data[d];
      if (val is String) {
        ls.pushString(d);
      } else if (val is int) {
        ls.pushInteger(val);
      } else if (val is bool) {
        ls.pushBoolean(val);
      }
      // Set variable name
      ls.setGlobal(d);
    }

    ls.loadString(chunk);

    await ls.call(0, 0);
    print("lua call done --- goodbye");
  }

  FutureOr<int> luaSleep(LuaState ls) async {
    print("start Dart Sleep for Lua");
    final delayInMs = ls.checkInteger(1);
    ls.pop(1);

    await Future<void>.delayed(Duration(milliseconds: delayInMs ?? 1));
    print("end Dart Sleep for Lua");
    return 1;
  }

  int luaPrint(LuaState ls) {
    final val = ls.checkInteger(1);
    ls.pop(1);

    print("lua print:$val");
    return 1;
  }
}