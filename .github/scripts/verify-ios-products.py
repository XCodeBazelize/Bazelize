#!/usr/bin/env python3
"""Compare actual iOS products, reject damaged copies, and observe a Simulator resource proof."""

import argparse
import json
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import tempfile
import time


COMPARER = Path(__file__).with_name('compare-bundles.py')
EXPECTED = {
    'resource': 'bazelize product resource\n',
    'extensionID': 'com.bazel.ProductProbe.Extension',
    'extensionPoint': 'com.apple.usernotifications.service',
    'icon': 'AppIcon',
    'alternateIcon': 'AlternateIcon',
    'framework': 'ProductProbeFramework',
}


def compare(reference, generated, baseline):
    return subprocess.run([sys.executable, str(COMPARER), '--reference', str(reference),
                           '--generated', str(generated), '--baseline', str(baseline),
                           '--entitlements'], capture_output=True, text=True)


def negative_checks(reference, generated, baseline):
    for damaged, diagnostic in [
        ('extension', 'missing:PlugIns/ProductProbeExtension.appex'),
        ('resource', 'missing:Probe.txt'),
        ('plist', 'plist:Info.plist:/CFBundleIdentifier'),
        ('alternate-icon', 'plist:Info.plist:/CFBundleIcons/CFBundleAlternateIcons/AlternateIcon/CFBundleIconName'),
    ]:
        with tempfile.TemporaryDirectory(prefix='bazelize-ios-negative-') as scratch:
            copy = Path(scratch) / generated.name
            shutil.copytree(generated, copy, symlinks=True)
            if damaged == 'extension':
                shutil.rmtree(copy / 'PlugIns/ProductProbeExtension.appex')
            elif damaged == 'resource':
                (copy / 'Probe.txt').unlink()
            else:
                path = copy / 'Info.plist'
                values = plistlib.loads(path.read_bytes())
                if damaged == 'alternate-icon':
                    values['CFBundleIcons']['CFBundleAlternateIcons']['AlternateIcon']['CFBundleIconName'] = 'WrongIcon'
                else:
                    values['CFBundleIdentifier'] = 'com.bazel.incorrect'
                path.write_bytes(plistlib.dumps(values))
            result = compare(reference, copy, baseline)
            if result.returncode == 0 or f'::error::{diagnostic}' not in result.stdout:
                raise RuntimeError(f'Damaged {damaged} was not rejected correctly:\n{result.stdout}\n{result.stderr}')
            print(f'PASS: damaged {damaged} rejected', flush=True)


def simctl(*arguments):
    return subprocess.check_output(['xcrun', 'simctl', *map(str, arguments)], text=True).strip()


def launch_proof(app, simulator):
    identifier = 'com.bazel.ProductProbe'
    stopped = subprocess.run(['xcrun', 'simctl', 'terminate', str(simulator), identifier],
                             capture_output=True, text=True)
    if stopped.returncode not in (0, 3):  # POSIX ESRCH: no process on a fresh install.
        raise RuntimeError(stopped.stderr)
    simctl('uninstall', simulator, identifier)
    simctl('install', simulator, app)
    container = Path(simctl('get_app_container', simulator, identifier, 'data'))
    proof = container / 'Documents/ProductProbe.json'
    proof.unlink(missing_ok=True)
    print(simctl('launch', simulator, identifier), flush=True)
    deadline = time.monotonic() + 60
    while not proof.is_file() and time.monotonic() < deadline:
        time.sleep(0.25)
    if not proof.is_file():
        raise RuntimeError('Launched app did not produce its resource/extension proof')
    observed = json.loads(proof.read_text())
    if observed != EXPECTED:
        raise RuntimeError(f'Runtime product mismatch: {observed!r}')
    print('PASS: Simulator runtime proof ' + json.dumps(observed, sort_keys=True), flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--reference', type=Path, required=True)
    parser.add_argument('--generated', type=Path, required=True)
    parser.add_argument('--baseline', type=Path, required=True)
    parser.add_argument('--simulator', help='booted Simulator UDID; omitted for comparison only')
    args = parser.parse_args()
    result = compare(args.reference, args.generated, args.baseline)
    print(result.stdout, end='', flush=True)
    if result.returncode:
        raise RuntimeError(result.stderr or 'iOS product comparison failed')
    negative_checks(args.reference, args.generated, args.baseline)
    if args.simulator:
        launch_proof(args.generated, args.simulator)


if __name__ == '__main__':
    main()
