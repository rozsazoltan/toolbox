import * as p from '@clack/prompts';
import {
  existsSync,
  readFileSync,
} from 'node:fs';
import {
  basename,
  join,
} from 'node:path';
import { runOrThrow } from '../lib/process.mjs';

export async function setupWslOpenCode() {
  p.intro('WSL OpenCode setup');

  if (process.platform !== 'win32') {
    p.log.error('Run this command from Windows.');
    return 1;
  }

  const profile = process.env.USERPROFILE;

  if (!profile) {
    p.log.error('USERPROFILE is not available.');
    return 1;
  }

  const openCodeDir = join(profile, '.config', 'opencode');
  const openCodeConfig = findFirst([
    join(openCodeDir, 'opencode.jsonc'),
    join(openCodeDir, 'opencode.json'),
  ]);

  if (!existsSync(openCodeDir) || !openCodeConfig) {
    p.log.error(`OpenCode config not found: ${openCodeDir}`);
    return 1;
  }

  const config = readFileSync(openCodeConfig, 'utf8');

  p.log.success(`OpenCode config: ${openCodeConfig}`);

  if (hasShellOverride(config)) {
    p.log.warn('Shared OpenCode config contains explicit "shell" setting.');
    p.log.warn('Remove Windows-only shell such as "pwsh" before sharing with WSL.');

    const continueAnyway = await p.confirm({
      message: 'Continue anyway?',
      initialValue: false,
    });

    if (p.isCancel(continueAnyway) || !continueAnyway) {
      p.cancel('No changes made.');
      return 0;
    }
  }

  const hasOmo = /"(?:oh-my-openagent|oh-my-opencode)(?:@[^"]+)?"/i.test(config);
  const omoConfig = findFirst([
    join(profile, '.omo', 'omo.jsonc'),
    join(profile, '.omo', 'omo.json'),
  ]);

  if (hasOmo) {
    p.log.success('oh-my-openagent plugin detected.');
  } else {
    p.log.warn('oh-my-openagent plugin not detected.');
  }

  let shareOmo = false;

  if (omoConfig) {
    p.log.success(`OMO config: ${omoConfig}`);

    const answer = await p.confirm({
      message: 'Share Windows OMO config with WSL?',
      initialValue: true,
    });

    if (p.isCancel(answer)) {
      p.cancel('Cancelled.');
      return 0;
    }

    shareOmo = answer;
  } else if (hasOmo) {
    p.log.warn('OMO plugin detected, but ~/.omo/omo.jsonc was not found.');
  }

  let distros;

  try {
    distros = getDistros();
  } catch (error) {
    p.log.error(error.message);
    return 1;
  }

  if (distros.length === 0) {
    p.log.error('No WSL distributions found.');
    return 1;
  }

  const scope = await p.select({
    message: 'Which WSL distributions should be configured?',
    options: [
      {
        value: 'all',
        label: 'All detected distributions',
        hint: 'recommended',
      },
      {
        value: 'one',
        label: 'Select one distribution',
      },
      {
        value: 'cancel',
        label: 'Cancel',
      },
    ],
    initialValue: 'all',
  });

  if (p.isCancel(scope) || scope === 'cancel') {
    p.cancel('Cancelled.');
    return 0;
  }

  let selectedDistros = distros;

  if (scope === 'one') {
    const distro = await p.select({
      message: 'Select WSL distribution',
      options: distros.map((value) => ({
        value,
        label: value,
      })),
      initialValue: distros[0],
    });

    if (p.isCancel(distro)) {
      p.cancel('Cancelled.');
      return 0;
    }

    selectedDistros = [distro];
  }

  const policy = await p.select({
    message: 'Existing WSL config?',
    options: [
      {
        value: 'backup',
        label: 'Back up and replace with symlink',
        hint: 'recommended',
      },
      {
        value: 'skip',
        label: 'Keep existing config',
      },
      {
        value: 'fail',
        label: 'Stop on conflict',
      },
    ],
    initialValue: 'backup',
  });

  if (p.isCancel(policy)) {
    p.cancel('Cancelled.');
    return 0;
  }

  const confirmed = await p.confirm({
    message: `Configure ${selectedDistros.join(', ')}?`,
    initialValue: true,
  });

  if (p.isCancel(confirmed) || !confirmed) {
    p.cancel('Cancelled.');
    return 0;
  }

  let failed = false;

  for (const distro of selectedDistros) {
    try {
      const openCodeSource = toWslPath(distro, openCodeDir);
      const omoSource = shareOmo && omoConfig
        ? toWslPath(distro, omoConfig)
        : '';

      configureDistro({
        distro,
        openCodeSource,
        omoSource,
        omoName: omoConfig ? basename(omoConfig) : '',
        policy,
      });

      p.log.success(`${distro} configured.`);
    } catch (error) {
      p.log.error(`${distro}: ${error.message}`);
      failed = true;
    }
  }

  p.note(
    [
      'Windows OpenCode config remains source of truth.',
      'CC Switch changes become visible in WSL immediately.',
      'MCP executables and other runtime dependencies still need to exist inside each distro.',
    ].join('\n'),
    'Done'
  );

  p.outro(failed ? 'Finished with errors.' : 'Setup complete.');

  return failed ? 1 : 0;
}

function findFirst(paths) {
  return paths.find((path) => existsSync(path)) ?? null;
}

function hasShellOverride(config) {
  const withoutComments = config
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/^\s*\/\/.*$/gm, '');

  return /^\s*"shell"\s*:/m.test(withoutComments);
}

function getDistros() {
  const result = runOrThrow('wsl.exe', ['--list', '--quiet']);
  const output = result.stdout.replace(/\0/g, '');

  return output
    .split(/\r?\n/)
    .map((distro) => distro.trim())
    .filter(Boolean)
    .filter((distro) => ![
      'docker-desktop',
      'docker-desktop-data',
    ].includes(distro.toLowerCase()));
}

function toWslPath(distro, windowsPath) {
  return runOrThrow(
    'wsl.exe',
    [
      '-d',
      distro,
      '--',
      'wslpath',
      '-a',
      '-u',
      windowsPath,
    ]
  ).stdout.trim();
}

function configureDistro({
  distro,
  openCodeSource,
  omoSource,
  omoName,
  policy,
}) {
  const script = String.raw`
set -euo pipefail

opencode_source="$1"
omo_source="$2"
omo_name="$3"
policy="$4"
timestamp="$(date +%Y%m%d-%H%M%S)"

link_target() {
  source="$1"
  target="$2"
  label="$3"

  mkdir -p "$(dirname "$target")"

  if [ -L "$target" ]; then
    current="$(readlink -f "$target" 2>/dev/null || true)"
    expected="$(readlink -f "$source" 2>/dev/null || true)"

    if [ -n "$expected" ] && [ "$current" = "$expected" ]; then
      printf '[OK] %s already linked\n' "$label"
      return
    fi
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    case "$policy" in
      backup)
        mv "$target" "${target}.backup-${timestamp}"
        ;;
      skip)
        printf '[SKIP] %s already exists\n' "$label"
        return
        ;;
      fail)
        printf '[ERR] %s already exists\n' "$label" >&2
        exit 10
        ;;
    esac
  fi

  ln -s "$source" "$target"
  printf '[OK] %s linked\n' "$label"
}

link_target \
  "$opencode_source" \
  "$HOME/.config/opencode" \
  "OpenCode config"

if [ -n "$omo_source" ]; then
  mkdir -p "$HOME/.omo"

  link_target \
    "$omo_source" \
    "$HOME/.omo/$omo_name" \
    "OMO config"
fi
`;

  runOrThrow(
    'wsl.exe',
    [
      '-d',
      distro,
      '--',
      'bash',
      '-lc',
      script,
      'toolbox',
      openCodeSource,
      omoSource,
      omoName,
      policy,
    ]
  );
}
