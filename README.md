# Toolbox

Personal collection of scripts and utilities for setting up, maintaining, and automating development environments across Windows, WSL, Linux, and macOS.

Repository focuses on reusable scripts that remove repetitive setup and maintenance work. Contents may grow over time as new workflows and tools become worth automating.

> [!CAUTION]
> These scripts are published in good faith and were created primarily to simplify my own development and maintenance workflows.
>
> They are personal tools shared publicly, not products or utilities designed, tested, or supported for general community use.
>
> Use them entirely at your own risk. Always review scripts before running them, especially commands that modify system configuration, install or remove software, manage files, or require elevated privileges.
>
> No guarantee is made that these scripts will work correctly in your environment or remain compatible with future system and tool changes.

## Bootstrap

Bootstrap prepares base environment required by Toolbox.

It will:

- install [`bin`](https://github.com/marcosnils/bin)
- install [`mise`](https://github.com/jdx/mise)
- configure persistent `PATH` entries
- configure `mise` shell activation
- install standalone tools managed by `bin`
- install global runtimes and packages managed by `mise`

Installed tools and versions are defined in [`bootstrap/tools.conf`](bootstrap/tools.conf). Same configuration is used by PowerShell and shell bootstrap scripts.

Most Toolbox functionality will be provided through an interactive PHP CLI. PHP is therefore part of base bootstrap environment rather than optional development dependency.

PHP is managed through [`verzly/mise-php`](https://github.com/verzly/mise-php). Windows uses standard binary installation. Linux and macOS use prebuilt static PHP to avoid source compilation and keep bootstrap fast.

### Linux and macOS

```sh
curl -fsSL https://raw.githubusercontent.com/rozsazoltan/toolbox/master/bootstrap/install.sh | sh
```

### Windows

```powershell
irm https://raw.githubusercontent.com/rozsazoltan/toolbox/master/bootstrap/install.ps1 | iex
```

## Scope

Current focus is scripts and development automation.

Repository may later include shared configuration, bootstrap files, or related tooling, but these are not considered part of stable structure yet.

## License

This repository is distributed under custom license based on GNU Affero General Public License v3.0.

See [LICENSE](LICENSE) for complete terms.
