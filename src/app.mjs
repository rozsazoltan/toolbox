import * as p from '@clack/prompts';
import { setupWslOpenCode } from './commands/wsl-opencode.mjs';

const commands = [
  {
    value: 'wsl:opencode',
    label: 'WSL OpenCode setup',
    hint: 'share Windows OpenCode config with WSL',
  },
];

export async function run(args) {
  const command = normalizeCommand(args);

  if (command === 'help') {
    printHelp();
    return 0;
  }

  if (command === 'wsl:opencode') {
    return setupWslOpenCode();
  }

  if (command) {
    p.log.error(`Unknown command: ${args.join(' ')}`);
    printHelp();
    return 1;
  }

  p.intro('Toolbox');

  const selected = await p.select({
    message: 'What do you want to do?',
    options: [
      ...commands,
      {
        value: 'exit',
        label: 'Exit',
      },
    ],
    initialValue: 'wsl:opencode',
  });

  if (p.isCancel(selected) || selected === 'exit') {
    p.cancel('Cancelled.');
    return 0;
  }

  if (selected === 'wsl:opencode') {
    return setupWslOpenCode();
  }

  return 0;
}

function normalizeCommand(args) {
  if (args.length === 0) {
    return null;
  }

  if (['help', '--help', '-h'].includes(args[0])) {
    return 'help';
  }

  if (args[0] === 'wsl' && args[1] === 'opencode') {
    return 'wsl:opencode';
  }

  if (args[0] === 'wsl:opencode') {
    return 'wsl:opencode';
  }

  return args.join(' ');
}

function printHelp() {
  console.log(`
Toolbox

Usage:
  toolbox
  toolbox wsl opencode
  toolbox wsl:opencode
  toolbox --help
`.trim());
}
