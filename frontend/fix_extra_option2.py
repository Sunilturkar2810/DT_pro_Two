import re

with open('lib/widget/assign_task_sheet.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# remove _extraOptionItem if it was inserted outside the class
if 'Widget _extraOptionItem' in text:
    part1 = text[:text.find('Widget _extraOptionItem')]
    part2 = text[text.find('Widget _extraOptionItem'):]
    part2 = part2[part2.find('}')+1:] # skip inner block
    part2 = part2[part2.find('}')+1:] # skip outer block
    # It might be easier to just use regex to replace it entirely
    # But since I know it's at the end, let's just do a clean replacement of everything below a certain point or just find the class.

