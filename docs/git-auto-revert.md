# `git auto-revert`

Revert commits based on a set of filters

## Synopsis

> `git auto-revert <commit-message-tag> [<options>]` \
  `git auto-revert --grep=<pattern> [<options>]`

## Description

`git auto-revert` allows you to revert commits that match a specified set of filters.
You can select commits based on a commit message tag (a prefix to the commit message)
or by using a pattern to match against commit messages.

## Options

__`<commit-message-tag>`__ \
A commit message tag used to filter commits. The tag is typically a prefix in the commit message. When specified, only commits with this tag as a prefix will be reverted.

__`-s`__ \
__`--single-commit`__ \
Apply all changes within a single commit. By default, `git auto-revert` creates separate revert commits for each commit that is reverted. With this option enabled, `git auto-revert` will create a single commit that reverts all the matched commits.

__`-m <msg>`__ \
__`--message=<msg>`__ \
Commit message for the single commit. Ignored if `--single-commit` is not enabled.

__`-n`__ \
__`--no-commit`__ \
Don't automatically commit.

__`--commit`__ \
Opposite of --no-commit.

__`-e`__ \
__`--[no-]edit`__ \
Edit the commit message before committing.

__`--[no-]auto-skip-empty`__ \
Automatically skip commits which introduce no change.
This option is enabled by default.

__`-v`__ \
__`--[no-]verbose`__ \
Be verbose. With this option enabled, `git auto-revert` will print which commits
are reverted and also the revert commits.

__`--grep=<pattern>`__ \
Limit the commits selected to ones with a log message that match the specified pattern. Required if commit message tag is not specified.

__`--author=<pattern>`__ \
Author of the commits to be selected. Set to `me` for the current user.

__`--committer=<pattern>`__ \
Committer of the commits to be selected. Set to `me` for the current user.

__`--since=<date>`__ \
__`--after=<date>`__ \
Limit commits selected to the ones that are more recent than a specific date.

__`--until=<date>`__ \
__`--before=<date>`__ \
Limit commits selected to the ones that are older than a specific date.

__`--since-commit=<commit>`__ \
__`--after-commit=<commit>`__ \
Limit commits selected to the ones that are more recent than the specified revision. (excluding specified revision)

__`--until-commit=<commit>`__ \
__`--before-commit=<commit>`__ \
Limit commits selected to the ones that are older than the specified revision. (including specified revision)

### Options related to limiting patterns

These options are applied when using the `--grep` option to search for commits.
(see [`git log`](https://git-scm.com/docs/git-log))

__`--all-match`__ \
Limit the commits selected to ones with a log message that matches all the given `--grep` patterns, instead of the ones that match at least one.

__`--invert-grep`__ \
Limit the commits selected to ones with a log message that do not match the pattern specified with `--grep=<pattern>`

__`-i`__ \
__`--regexp-ignore-case`__ \
Match the regular expression limiting patterns without regard to letter case.

__`--basic-regexp`__ \
Consider the limiting patterns to be basic regular expressions; this is the default.

__`-E`__ \
__`--extended-regexp`__ \
Consider the limiting patterns to be extended regular expressions instead of the default basic regular expressions.

__`-F`__ \
__`--fixed-strings`__ \
Consider the limiting patterns to be fixed strings. (don't interpret pattern as a regular expression)

__`-P`__ \
__`--perl-regex`__ \
Consider the limiting patterns to be Perl-compatible regular expressions.

## Configuration

__`autoRevert.verbose`__ \
Setting this variable to true enables verbose output for `git auto-revert` by default.
This behavior can be overridden by using the `--no-verbose` option.
