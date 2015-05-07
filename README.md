NAME
====

RedBlackTree

VERSION
=======

0.01

SYNOPSIS
========

    use RedBlackTree;

    my $tree = RedBlackTree.new;
    $tree.insert('foo', 17);
    $tree.insert('bar', 18);
    $tree.insert('baz', 19);

    my @keys = gather for $tree.keys { take $_ };

DESCRIPTION
===========

This module implements a red-black tree data structure where each node has a key and value. Its intended use is for helping to implement associative containers with ordered keys for things like range queries, but it's still very young.

INVARIANTS
==========

Red-black trees have a set of properties that must always hold true, but they can take some time to check on large trees. If you want the code to check them (for debugging or testing purposes, usualy), you can set `$*RB-CHECK-INVARIANTS` to a truthy value.

AUTHOR
======

Rob Hoelz <rob AT-SIGN hoelz.ro>
