# `git reapply`

Reapply previously reverted commits based on a set of filters

## Synopsis

> `git reapply <commit-message-tag> [<options>]` \
  `git reapply --grep=<pattern> [<options>]`

## Description

`git reapply` allows you to reapply commits that were previously reverted, or commits that exist in another revision but not in the current one, based on a specified set of filters. You can select commits based on a commit message tag or patterns, similar to `git auto-revert`

## Options

__`<commit-message-tag>`__ \
A commit message tag used to filter commits. The tag is typically a prefix in the commit message. When specified, only commits with this tag as a prefix will be reverted.

__`--source`__ \
Source revision that commits are searched from. Typically the source branch that the commits are located.

__`--[no-]decorate-messages`__ \
Add decoration to auto-generated commit messages to indicate they were reapplied, including the hash of the original commit. This is enabled by default, unless `--source` is specified. You can still enable it when `--source` is used by explicitly setting this option.

__`-s`__ \
__`--single-commit`__ \
Apply all changes within a single commit. By default, `git reapply` creates separate commits for each commit that is reapplied. With this option enabled, `git reapply` will create a single commit that applies the changes introduced by all the matched commits.

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
Be verbose. With this option enabled, `git reapply` will print which commits
are applied and also the created commits.

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

## Examples

__`git reapply TASK-123`__ \
Reapply all commits whose log message starts with `TASK-123` (optionally followed by a colon).
This is useful for automatically reapplying commits associated with a specific task or issue, typically referenced by its identifier.

For example, the following commits would be matched and reapplied:

```console
$ git log 
cac83ad TASK-123: make some changes on my feature
fdcd576 TASK-123 implement my feature
```

__`git reapply "feat(my-feature)"`__ \
Reapply all commits whose log message starts with `feat(my-feature)`, following the same pattern as the previous example.

For example, the following commits would be matched and reapplied:

```console
$ git log 
8c3cc95 feat(my-feature): make some changes on my feature
6ad380b feat(my-feature) implement my feature
```

__`git reapply TASK-123 --source=development`__ \
Reapply all commits whose log message starts with `TASK-123`, but from the specified source branch or revision (in this case, `development`).
This is useful for selectively cherry-picking commits from another branch or revision (e.g. `development`) and reapplying them to the current branch.

__`git reapply --grep="^TASK" --grep="feature$"`__ \
Reapply all commits whose log messages match both the patterns `^TASK` (starting with "TASK") and `feature$` (ending with "feature").
This is useful when you can't match commits by a specific task ID or exact keyword but need to apply more flexible filters.

__`git reapply TASK-123 --single-commit`__ \
Reapply all commits whose log message starts with `TASK-123`,
and combine them into a single reapply commit, rather than creating separate commits for each reapply.
This is useful when reapplying several commits at once, especially if you want to keep the history clean.

The resulting reapply commit will look like this:

```console
$ git show -s HEAD
commit 92df020c503df8fa7d891350ddb85e6baae63c41 (HEAD -> my-feature)
Author: John Doe <john.doe@example.com>
Date:   Wed Jan 1 00:00:00 2025

    Reapply "TASK-123"
    
    This reapplies commit 9dec7683ebb507d9be93a72824b7c1b21af45571.
    This reapplies commit 1d818c498d32e4825778ee74d8bb1027ecf27d0c.
```

__`git reapply TASK-123 --no-commit`__ \
Reapply all commits whose log message starts with `TASK-123`, but do not make a new commit automatically.

__`git reapply TASK-123 --author=me`__ \
Reapply all commits whose log message starts with `TASK-123` and authored by the current user.

__`git reapply TASK-123 --committer=me`__ \
Reapply all commits whose log message starts with `TASK-123` and committed by the current user.

__`git reapply TASK-123 --since="2 weeks ago" --until="yesterday"`__ \
Reapply all commits whose log message starts with `TASK-123` and were made between the specified dates (from 2 weeks ago to yesterday).

__`git reapply TASK-123 --since-commit="v1.2" --until-commit="HEAD~2"`__ \
Reapply all commits whose log message starts with `TASK-123` and were made within the specified range of revisions (from tag v1.2 to revision HEAD~2).

## Configuration

__`reapply.verbose`__ \
Setting this variable to true enables verbose output for `git reapply` by default.
This behavior can be overridden by using the `--no-verbose` option.
