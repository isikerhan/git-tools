# `git squash`

Squash the most recent commits into a single commit

## Synopsis

> `git squash <base-commit> [<options>]` \
  `git squash (-n | --number-of-commits) <number> [<options>]` \
  `git squash --root [<options>]`

## Description

`git squash` allows you to combine (squash) multiple commits into a single commit, starting from the most recent commit (`HEAD`). This can be useful for cleaning up commit history before merging into a shared
working branch.

You can squash:

- __Onto a base commit__: Squash all commits between `HEAD` and a commit specified as `<base-commit>`. (Excluding the base commit)
- __The last n commits__: Squash a specific number of the most recent commits using `-n` (or `--number-of-commits`) option.
- __The entire commit history__: Squash all commits in the current branch into a single commit using `--root` option.

## Options

__`-n <number>`__ \
__`--number-of-commits=<number>`__ \
Number of commits starting from `HEAD` to squash.

__`-m <msg>`__ \
__`--message=<msg>`__ \
Commit message for the newly created squashed commit.

__`--no-commit`__ \
Don't automatically commit.

__`--commit`__ \
Opposite of `--no-commit`.

__`-e`__ \
__`--[no-]edit`__ \
Edit the commit message.

__`--allow-empty`__ \
Allow creating an empty commit when the commits being squashed introduce no change over the base commit.

__`--empty=(drop|keep|abort)`__ \
How to handle when commits being squashed end up in an empty changeset.

&nbsp;&nbsp;&nbsp;&nbsp; __`drop`__&nbsp;&nbsp;&nbsp;&nbsp;The commits will be dropped. \
&nbsp;&nbsp;&nbsp;&nbsp; __`keep`__&nbsp;&nbsp;&nbsp;&nbsp;An empty commit will be created. Implies `--allow-empty`. \
&nbsp;&nbsp;&nbsp;&nbsp; __`abort`__&nbsp;&nbsp;&nbsp;The squash operation will abort and the working tree will be reset to its state before the squash. This is the default behavior.

__`--root`__ \
Squash all the commits that are reachable from `HEAD`.

__`-v`__ \
__`--[no-]verbose`__ \
Be verbose. With this option enabled, `git squash` will print which commits
are squashed into which commit.
