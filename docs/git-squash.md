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

## Examples

__`git squash -n 3`__ \
Squash latest 3 commits.

__`git squash HEAD~3`__ \
Squash latest commits after `HEAD~3`. This is equivalent to running `git squash -n 3`.

__`git squash development`__ \
Squash all the commits which are not present in development but in the current branch.
This is useful if you work on a repository where all the feature branches are merged
into a common branch such as "development" and you want to keep the commit history clean.
The target revision (in this case, development) must be reachable from the tip
of your branch. So make sure to rebase your branch with the target branch or revision
before using this command.

```console
git rebase development
git squash development
```

or squash against a remote branch:

```console
git fetch
git rebase origin/development
git squash origin/development 
```

or against a tag:

```console
git fetch --tags
git rebase v1.2
git squash v1.2
```

__`git squash --root`__ \
Squash all the commits starting from the `HEAD` down to the root commit.
This squashes all the history reachable from the current `HEAD`.

__`git squash --number-of-commits 5 --message "hello world!"`__ \
Squash latest 5 commits and use the specified message as the log message.

__`git squash -n 5 --no-commit`__ \
Squash latest 5 commits, but do not make a new commit automatically.

## Configuration

__`squash.verbose`__ \
Setting this variable to true enables verbose output for `git squash` by default.
This behavior can be overridden by using the `--no-verbose` option.
