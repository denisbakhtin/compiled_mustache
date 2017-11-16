import 'dart:io';
import 'package:grinder/grinder.dart';
import 'package:path/path.dart' as path;


main(args) => grind(args);


Future _forEachBenchmark(void preProcess(String), void postProcess(ProcessResult)) async {
  var benchmarks = await new Directory('benchmark').listSync();
  var first = true;
  for (var file in benchmarks) {
    if (file is File && path.extension(file.path) == ".dart") {
      String name = path.basename(file.path);
      
      preProcess(name);
      ProcessResult results = await Process.run('dart', ['benchmark/$name']);
      postProcess(results);
    }
  }
}


@Task()
Future test() => new TestRunner().testAsync();


@Task()
Future benchmark() async {
  var first = true;
  await _forEachBenchmark((String name) {
    if (!first) { log('\n'); }
    first = false;
    log('Running benchmark \'${path.basenameWithoutExtension(name)}\'');
  }, (ProcessResult pr) {
    log(pr.stdout);
  });
}


@Task()
Future doc() async {
  ProcessResult results = await Process.run('dartdoc', []);
  log(results.stdout);
  
  log('Generating benchmarks.md...');
  // Document benchmark results
  var benchmarkDoc = await new File('doc/benchmarks.md');
  if (!benchmarkDoc.existsSync()) {
    benchmarkDoc.createSync(recursive: true);
  }
  
  String contents = '<!-- THIS FILE IS AUTOGENERATED BY \'grind doc\'; DO NOT MODIFY -->\n\n'
                  'Benchmarks\n'
                  '==========';
  
  await _forEachBenchmark((String name) {
    var n = path.basenameWithoutExtension(name);
    log('Running benchmark \'$n\'');
    contents += '\n\n## $n\n';
  }, (ProcessResult pr) {
    contents += '```\n';
    contents += pr.stdout;
    contents += '```';
  });
  benchmarkDoc.writeAsString(contents);
}


@DefaultTask()
@Depends(test)
void build() {
  Pub.build();
}


@Task()
void clean() => defaultClean();