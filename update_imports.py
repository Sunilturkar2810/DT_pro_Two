with open('lib/widget/assign_task_sheet.dart', 'r', encoding='utf-8') as f:
    text = f.read()

import_statement = '''import 'package:d_table_delegate_system/model/user_model.dart';
import 'package:d_table_delegate_system/model/tag_model.dart';
import 'package:d_table_delegate_system/provider/tag_provider.dart';'''

text = text.replace('import \'package:d_table_delegate_system/model/user_model.dart\';', import_statement)

with open('lib/widget/assign_task_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print('Done!')
