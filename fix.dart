import 'dart:io';

void main() {
  final file = File('lib/widget/assign_task_sheet.dart');
  var content = file.readAsStringSync();
  
  // Replace => setState(() => X) with => setState(() { X; })
  content = content.replaceAllMapped(
    RegExp(r'setState\(\(\)\s*=>\s*([^)]+)\)'), 
    (match) => 'setState(() { ${match.group(1)}; })'
  );

  // Replace setD(() => X) with setD(() { X; })
  content = content.replaceAllMapped(
    RegExp(r'setD\(\(\)\s*=>\s*([^)]+)\)'), 
    (match) => 'setD(() { ${match.group(1)}; })'
  );

  // Replace setModal(() => X) with setModal(() { X; })
  content = content.replaceAllMapped(
    RegExp(r'setModal\(\(\)\s*=>\s*([^)]+)\)'), 
    (match) => 'setModal(() { ${match.group(1)}; })'
  );

  // Replace setModalState(() => X)
  content = content.replaceAllMapped(
    RegExp(r'setModalState\(\(\)\s*=>\s*([^)]+)\)'), 
    (match) => 'setModalState(() { ${match.group(1)}; })'
  );

  file.writeAsStringSync(content);
  print('Fixed closures!');
}
