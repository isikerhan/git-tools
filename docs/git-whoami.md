# `git whoami`

Print current Git user information

## Synopsis

> `git whoami [<options>]`

## Description

`git whoami` prints the current Git user information.

## Options

__`-s`__ \
__`--short`__ \
Print the user information in short format (only the name).

__`--long`__ \
Print the full user information. This is the default.

## Examples

__`git whoami`__ \
Print the full current user information.

```console
$ git whoami
John Doe <john.doe@example.com>
```

__`git whoami -s`__ \
Print only the name of the current user.

```console
$ git whoami -s
John Doe
```
