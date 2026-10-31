"""Select conditional source lines before parsing BugFS or BugVM files."""

import re


def select_defines(src, defines):
    defines = set(defines)
    selected = []
    active = True
    stack = []

    for line in src.splitlines(keepends=True):
        condition = re.fullmatch(r'\s*IF DEF\((ALPHA|BETA|DEBUG)\)\s*', line)
        if condition:
            stack.append((active, condition.group(1) in defines, False))
            active = active and condition.group(1) in defines
        elif line.strip() == 'ELSE':
            if not stack or stack[-1][2]:
                raise ValueError('Unexpected ELSE in conditional source')
            parent, matched, _ = stack[-1]
            stack[-1] = (parent, matched, True)
            active = parent and not matched
        elif line.strip() == 'ENDC':
            if not stack:
                raise ValueError('ENDC without IF DEF in conditional source')
            active = stack.pop()[0]
        elif active:
            selected.append(line)

    if stack:
        raise ValueError('Unclosed IF DEF in conditional source')
    return ''.join(selected)
