"""Run on a Codemagic Mac; capture native simulator displays without resizing."""
import json
import os
from pathlib import Path
import struct
import subprocess
import zipfile


def run(*args, **kwargs):
    return subprocess.run(args, check=True, text=True, **kwargs)


def sim_json(*args):
    return json.loads(run('xcrun', 'simctl', *args, capture_output=True).stdout)


def main():
    output = Path('build/store-screenshots').resolve()
    output.mkdir(parents=True, exist_ok=True)
    runtimes = [r for r in sim_json('list', 'runtimes', '--json')['runtimes']
                if r.get('isAvailable') and 'iOS' in r['name']]
    if not runtimes:
        raise RuntimeError('No iOS simulator runtime installed on this Mac')
    runtime = max(runtimes, key=lambda r: tuple(map(int, r['version'].split('.'))))
    types = {d['name']: d['identifier']
             for d in sim_json('list', 'devicetypes', '--json')['devicetypes']}
    targets = [
        ('iphone', ['iPhone 16 Pro Max', 'iPhone 17 Pro Max', 'iPhone 15 Pro Max'],
         {(1320, 2868), (1290, 2796), (1260, 2736)}),
        ('ipad', ['iPad Pro 13-inch (M4)', 'iPad Pro 13-inch (M5)',
                  'iPad Pro (12.9-inch) (6th generation)'],
         {(2064, 2752), (2048, 2732)}),
    ]
    manifest = []
    for group, candidates, allowed_sizes in targets:
        model = next((name for name in candidates if name in types), None)
        if not model:
            raise RuntimeError(f'No supported {group} model. Available: {list(types)}')
        device = run('xcrun', 'simctl', 'create', f'Store screenshots {group}',
                     types[model], runtime['identifier'], capture_output=True).stdout.strip()
        try:
            run('xcrun', 'simctl', 'boot', device)
            run('xcrun', 'simctl', 'bootstatus', device, '-b')
            run('xcrun', 'simctl', 'status_bar', device, 'override',
                '--time', '9:41', '--dataNetwork', 'wifi', '--wifiMode', 'active',
                '--wifiBars', '3', '--batteryState', 'charged', '--batteryLevel', '100')
            run('xcrun', 'simctl', 'privacy', device, 'grant', 'location',
                'com.divinewall.divinewall')
            folder = output / group
            folder.mkdir(exist_ok=True)
            env = dict(os.environ, SCREENSHOT_DEVICE_ID=device,
                       SCREENSHOT_OUTPUT=str(folder))
            run('flutter', 'drive', '--driver=test_driver/store_screenshots.dart',
                '--target=integration_test/store_screenshots_test.dart',
                '-d', device, env=env)
            screenshots = sorted(folder.glob('*.png'))
            if len(screenshots) != 3:
                raise RuntimeError(f'Expected 3 screenshots for {group}')
            for path in screenshots:
                header = path.read_bytes()[:24]
                if header[:8] != b'\x89PNG\r\n\x1a\n':
                    raise RuntimeError(f'Invalid PNG: {path}')
                size = struct.unpack('>II', header[16:24])
                if size not in allowed_sizes:
                    raise RuntimeError(f'Unsupported App Store screenshot size: {size}')
                manifest.append(dict(file=str(path.relative_to(output)),
                                     device=model, width=size[0], height=size[1]))
        finally:
            subprocess.run(['xcrun', 'simctl', 'shutdown', device], check=False)
            subprocess.run(['xcrun', 'simctl', 'delete', device], check=False)
    (output / 'manifest.json').write_text(json.dumps(manifest, indent=2))
    with zipfile.ZipFile(output.parent / 'store-screenshots.zip', 'w',
                         zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(output.rglob('*')):
            if path.is_file():
                archive.write(path, path.relative_to(output))
    print('Created build/store-screenshots.zip with six screenshots.')


if __name__ == '__main__':
    main()
