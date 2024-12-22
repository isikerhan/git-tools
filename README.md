# Git Tools :hammer_and_wrench:

A set of custom Git commands that might come in handy for certain tasks.

## Prerequisites

Before installing Git Tools, ensure your system meets the following requirements:

- __Bash__: This project is intended to run in a Bash shell. Most Unix-based systems (Linux, macOS) come with Bash pre-installed.

- __Git v2.22+__: Git Tools requires [Git](https://git-scm.com/downloads) version 2.22 or higher.

## Installation

You can either install Git Tools from the source or download a release.

- __Download a Release or Clone the Repository__: Go to the [releases](https://github.com/isikerhan/git-tools/releases) page to download a release and extract it, or clone the repository to a desired location.
- __Add the `git-tools` Directory to Your `PATH`__: To add the `git-tools` directory to your `PATH`,
add the following line to `~/.bashrc`:

    ```console
    export PATH="$PATH:/path/to/git-tools"
    ```

    Replace `/path/to/git-tools` with the actual path where you placed Git Tools.
- __Reload Your Shell__: To apply the changes, either restart your terminal or run the following command:

    ```console
    source ~/.bashrc
    ```

## Available Commands

Once you install Git Tools, the following commands will be available for use:

- [__`git auto-revert`__](docs/git-auto-revert.md) Revert commits based on a set of filters

- [__`git reapply`__](docs/git-reapply.md) Reapply previously reverted commits based on a set of filters

- [__`git squash`__](docs/git-squash.md) Squash the most recent commits into a single commit
