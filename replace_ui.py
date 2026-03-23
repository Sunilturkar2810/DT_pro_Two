import re

with open('lib/widget/assign_task_sheet.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# I want to replace everything from   // --- Build ------------------- to   void _showUserPicker
# wait, let me just find exactly where build starts and where the dialogs start.
