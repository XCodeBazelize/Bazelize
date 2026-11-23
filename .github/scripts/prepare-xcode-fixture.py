#!/usr/bin/env python3
"""Make Tuist's implicit empty copy destinations explicit for Xcode's JSON converter."""

import json
from pathlib import Path
import re
import subprocess


PROJECT = Path(__file__).resolve().parents[2] / 'fixture/iOS/Example.xcodeproj/project.pbxproj'


def main():
    model = json.loads(subprocess.check_output(
        ['plutil', '-convert', 'json', '-o', '-', str(PROJECT)], text=True))
    contents = PROJECT.read_text()
    changed = 0
    for identifier, value in model['objects'].items():
        if value.get('isa') != 'PBXCopyFilesBuildPhase' or 'dstPath' in value:
            continue
        # The decoded object identifies the one generated OpenStep block to edit;
        # retain the traditional project format and every other property verbatim.
        block = re.compile(rf'(?m)^([ \t]*){re.escape(identifier)}(?: /\* [^\n]* \*/)? = \{{\n')
        contents, count = block.subn(lambda match: match.group(0) + match.group(1) + '\tdstPath = "";\n', contents)
        if count != 1:
            raise RuntimeError(f'Expected exactly one copy phase block for {identifier}')
        changed += 1
    if changed:
        PROJECT.write_text(contents)
    print(f'Made {changed} implicit copy destination(s) explicit')


if __name__ == '__main__':
    main()
