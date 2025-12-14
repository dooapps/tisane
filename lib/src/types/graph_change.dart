import 'tt.dart';
import 'generic.dart';

typedef ChangeSetEntry = Tuple<String, TTGraphData>;
typedef ChangeSetEntryFunc = Future<ChangeSetEntry?> Function();
typedef VoidCallback = void Function();
typedef SetChangeSetEntryFunc = void Function(ChangeSetEntry change);
