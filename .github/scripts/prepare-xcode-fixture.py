#!/usr/bin/env python3
"""Prepare Tuist's copy destinations and watchOS Intents product type for Xcode."""

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
        # Tuist has no Intents service product. Retype the watchOS fixture so
        # both Xcode and Bazel exercise the actual product, not a generic extension.
        if value.get('isa') == 'PBXNativeTarget' and value.get('name') == 'WatchCompanionIntents':
            old = 'productType = "com.apple.product-type.app-extension";'
            new = 'productType = "com.apple.product-type.app-extension.intents-service";'
            block = re.compile(rf'(?ms)^([ \t]*){re.escape(identifier)}(?: /\* [^\n]* \*/)? = \{{\n.*?^\1\}};')
            def retype(match):
                target = match.group(0)
                if old not in target and new not in target:
                    raise RuntimeError('Unexpected product type for WatchCompanionIntents')
                return target.replace(old, new)
            contents, count = block.subn(retype, contents)
            if count != 1:
                raise RuntimeError('Expected exactly one WatchCompanionIntents target')
            changed += value.get('productType') != 'com.apple.product-type.app-extension.intents-service'
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
    print(f'Prepared {changed} fixture object(s)')


if __name__ == '__main__':
    main()
