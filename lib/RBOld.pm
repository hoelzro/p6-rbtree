use v6;

constant $VERSION = '0.01';

my enum RBColor <Black Red>;

my class RBNode {
    has $.key;
    has $.value is rw;
    has RBColor $!color = RBColor::Red;
    has RBNode $.left  is rw;
    has RBNode $.right is rw;
    has RBNode $.parent is rw; # XXX remove me later

    method color is rw { self.defined ?? $!color !! Black }

    method is-black { $.color == RBColor::Black }
    method is-red   { $.color == RBColor::Red }
}

# XXX can you have multiple values for a key?
class RedBlackTree {
    has &!cmp;
    has RBNode $!root;

    submethod BUILD(:&!cmp = &[before]) {}

    sub assert(Bool $cond) {
        die "assertion failed"
    }

    method insert($key, $value) {
        my $grandparent = RBNode;
        my $parent      = $!root;
        my $uncle       = RBNode;
        my $child-cont := $!root;

        my sub rotate-left(RBNode $node, RBNode $_parent = $node.parent) {
            my $parent = $node.parent;
            assert $parent === $_parent;
            my $cont := $node === $parent.left ?? $parent.left !! $parent.right;

            $cont = $node.right;
        }

        my sub rotate-right(RBNode $node, RBNode $_parent = $node.parent) {
            my $parent = $node.parent;
        }

        my sub insert-helper($grandparent, $uncle, $parent is rw, $node) {
            assert($grandparent === $parent.parent);
            assert($uncle === $grandparent.defined ?? ($parent === $grandparent.left ?? $grandparent.right !! $grandparent.left) !! RBNode);

            if $parent.defined {
                if &!cmp($node.key, $parent.key) {
                    insert-helper($parent, $parent.right, $parent.left, $node);
                } else {
                    insert-helper($parent, $parent.left, $parent.right, $node);
                }

                if $parent.is-red {
                    if $uncle.is-red {
                        $parent.color      = $uncle.color  = RBColor::Black;
                        $grandparent.color = RBColor::Red;
                    } else {
                        # XXX we have no guarantee $node is a child of $parent here, since
                        #     a recursive call further down could have inserted it
                        if $node === $parent.right && $parent === $grandparent.left {
                            rotate-left($parent, $grandparent);
                        } elsif $node === $parent.left && $parent === $grandparent.right {
                            rotate-right($parent, $grandparent);
                        }

                        $parent.color      = RBColor::Black;
                        $grandparent.color = RBColor::Red;
                        if $node === $parent.left && $parent === $grandparent.left {
                            rotate-right($grandparent);
                        } else {
                            rotate-left($grandparent);
                        }
                    }
                }
            } else {
                $parent = $node;
            }
        }

        # XXX can we fold this in to insert-helper? (I think it's already done)
        if $!root.defined {
            insert-helper(RBNode, RBNode, $!root, RBNode.new(
                :$key,
                :$value,
            ));
        } else {
            $!root = RBNode.new(
                :$key,
                :$value,
            );
        }

        if $!root.is-red {
            $!root.color = RBColor::Black;
        }
    }

    method lookup($key) {
    }
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
