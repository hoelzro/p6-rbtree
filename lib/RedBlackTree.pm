use v6;

my enum RBColor <Black Red>;
my class RBNode {
    has $.key;
    has $.value is rw;
    has RBColor $!color;

    has RBNode $.left is rw;
    has RBNode $.right is rw;

    submethod BUILD(:$!key!, :$!value!, :$!color = RBColor::Red) {}

    method color is rw { self.defined ?? $!color !! RBColor::Black }

    method is-black { $.color == RBColor::Black }
    method is-red   { $.color == RBColor::Red   }

    method blacken { $!color = RBColor::Black }
    method redden  { $!color = RBColor::Red   }

    multi method gist(RBNode:U) {
        'RBNode'
    }

    multi method gist(RBNode:D:) {
        "RBNode(key => $!key.gist(), value => $!value.gist(), color => $!color.gist(), left => {$!left ?? ~$!left !! '(RBNode)'}, right => {$!right ?? ~$!right !! '(RBNode)'})"
    }
}

my $*RB_DEBUG = False;

my sub debug($msg) {
    say $msg if $*RB_DEBUG;
}

class RedBlackTreeInvariantViolation is X::Phaser::PrePost {
    has $.message;
}

class RedBlackTree {
    has RBNode $!root;
    has &!cmp;

    submethod BUILD(:&!cmp = &[cmp]) {}

    method !check-nodes(&predicate) {
        my sub helper(RBNode $node) {
            predicate($node) &&
            (!$node.left || predicate($node.left)) &&
            (!$node.right || predicate($node.right))
        }

        if $!root {
            helper($!root);
        } else {
            True
        }
    }

    method !paths($node) {
        my sub helper($node, @current-path is copy) {
            unless $node {
                take @current-path.item;
                return;
            }

            my @new-path = @current-path, $node;

            helper($node.left,  @new-path);
            helper($node.right, @new-path);
        }

        gather {
            helper($!root, []);
        }
    }

    my sub rotate-left(RBNode $node) {
        die "no right child for left rotation" unless $node.right;

        my $new-node = $node.right;

        $node.right    = $new-node.left;
        $new-node.left = $node;

        $new-node
    }

    my sub rotate-right(RBNode $node) {
        die "no left child for right rotation" unless $node.left;

        my $new-node = $node.left;

        $node.left      = $new-node.right;
        $new-node.right = $node;

        $new-node
    }

    method !insert-helper(RBNode $current is copy, RBNode $parent, RBNode $grandparent, RBNode $uncle, RBNode $insert-me) {
        my ( $node, $check-me ) = do if $current {
            my $sibling = $parent ?? ($current === $parent.left ?? $parent.right !! $parent.left) !! RBNode;
            my $check-me;
            my $child = do given &!cmp($insert-me.key, $current.key) {
                when Order::Same {
                    # XXX we may allow an :$overwrite option in the future
                    $current.value = $insert-me.value;
                    return $current, RBNode;
                }

                when Order::Less {
                    ($current.left, $check-me) = self!insert-helper($current.left, $current, $parent, $sibling, $insert-me);
                    $current.left
                }

                when Order::More {
                    ($current.right, $check-me) = self!insert-helper($current.right, $current, $parent, $sibling, $insert-me);
                    $current.right
                }
            }

            return $current unless $check-me;

            if $check-me === $child && $parent {
                if $current.is-red && $sibling.is-black {
                    if $child === $current.right && $current === $parent.left {
                        return rotate-left($current), $current;
                    } elsif $child === $current.left && $current === $parent.right {
                        return rotate-right($current), $current;
                    }
                }
            }

            if $check-me === ($child.left|$child.right) {
                my $other-child = $child === $current.left ?? $current.right !! $current.left;

                if $child.is-red && $other-child.is-black {
                    if $child === $current.left && $child.left.is-red {
                        $child.blacken;
                        $current.redden;
                        $current = rotate-right($current);
                    } elsif $child === $current.right && $child.right.is-red {
                        $child.blacken;
                        $current.redden;
                        $current = rotate-left($current);
                    }
                }
            }

            $current, $check-me
        } else {
            $insert-me, $insert-me
        }

        if $check-me === $node {
            if $parent {
                if $parent.is-red {
                    if $uncle.is-red {
                        $parent.blacken;
                        $uncle.blacken;
                        $grandparent.redden;
                        return $node, $grandparent;
                    }
                } else {
                    return $node, RBNode;
                }
            } else {
                $node.blacken;
                return $node, RBNode;
            }
        }
        return $node, $check-me;
    }

    method insert($key, $value) {
        POST {
            self.POST;
        }

        ( $!root, $ ) = self!insert-helper($!root, RBNode, RBNode, RBNode, RBNode.new(
            :$key,
            :$value,
        ));
    }

    method dump {
        my multi color(RBNode $node where *.is-black, Str $s) {
            "\e[37;40;1m$s\e[0m"
        }
        my multi color(RBNode $node where *.is-red, Str $s) {
            "\e[30;41;1m$s\e[0m";
        }
        my sub dump-node(RBNode $node, $indent) returns Str {
            return ' ' x $indent ~ color($node, "(nil)") ~ "\n" if !$node.defined;

            my $dump = ' ' x $indent ~ color($node, "$node.key() $node.value()") ~ "\n";
            $dump ~= dump-node($node.left, $indent + 1);
            $dump ~= dump-node($node.right, $indent + 1);
            $dump
        }

        dump-node($!root, 0);
    }

    method keys {
        my sub helper(RBNode $node) {
            return unless $node;

            helper($node.left);
            take $node.key;
            helper($node.right);
        }
        gather {
            helper($!root);
        }
    }

    method !count-black-nodes(RBNode $node) {
        return 1 unless $node;

        my $left-count  = self!count-black-nodes($node.left);
        my $right-count = self!count-black-nodes($node.right);

        return unless $left-count.defined && $right-count.defined;
        return unless $left-count == $right-count;

        return ($node.is-black ?? 1 !! 0) + $left-count;
    }

    submethod POST {
        return True unless $*RB-CHECK-INVARIANTS;

        # condition 1 (a node is either red or black) is satisified by
        # the type system

        unless $!root.is-black {
            RedBlackTreeInvariantViolation.new(:message('Root must be black')).throw;
        }

        # condition 3 (all leaves are black) is satisified by the type
        # system (all undefined RBNodes are black)

        my $all-red-children-black = self!check-nodes({
            $^node.is-black || ($^node.left.is-black && $^node.right.is-black)
        });

        unless $all-red-children-black {
            RedBlackTreeInvariantViolation.new(:message(q{All red nodes' children must be black})).throw;
        }

        my $black-node-count = self!count-black-nodes($!root);

        unless $black-node-count.defined {
            RedBlackTreeInvariantViolation.new(:message('All paths from a node to a leaf must contain the same number of black nodes')).throw;
        }

        True
    }
}
