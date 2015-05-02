use v6;

constant $VERSION = '0.01';

class RedBlackTree {
}

=begin NAME
RedBlackTree
=end NAME

=begin VERSION
A<$VERSION>
=end VERSION

=begin SYNOPSIS
    use RedBlackTree;

    my $tree = RedBlackTree.new;

    $tree.insert('foo', 1);
    $tree.insert('bar', 2);
    $tree.insert('baz', 3);

    say $tree.lookup('bar'); # 2
=end SYNOPSIS

=begin DESCRIPTION
This class implements a red-black tree.
=end DESCRIPTION

=begin AUTHOR
Rob Hoelz <rob AT-SIGN hoelz.ro>
=end AUTHOR
