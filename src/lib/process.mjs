import { spawnSync } from 'node:child_process';

export function run(command, args = [], options = {}) {
  const result = spawnSync(command, args, {
    encoding: 'utf8',
    shell: false,
    ...options,
  });

  if (result.error) {
    throw result.error;
  }

  return {
    status: result.status ?? 1,
    stdout: result.stdout ?? '',
    stderr: result.stderr ?? '',
  };
}

export function runOrThrow(command, args = [], options = {}) {
  const result = run(command, args, options);

  if (result.status !== 0) {
    throw new Error(
      result.stderr.trim()
      || result.stdout.trim()
      || `${command} exited with code ${result.status}`
    );
  }

  return result;
}
