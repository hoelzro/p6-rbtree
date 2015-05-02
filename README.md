NAME
====

RedBlackTree

VERSION
=======

0.01

SYNOPSIS
========

```perl6
    use RedBlackTree;

    my $tree = RedBlackTree.new;

    $tree.insert('foo', 1);
    $tree.insert('bar', 2);
    $tree.insert('baz', 3);

    say $tree.lookup('bar'); # 2
```

DESCRIPTION
===========

This class implements a red-black tree.

AUTHOR
======

Rob Hoelz <rob AT-SIGN hoelz.ro>
