use v6;

my enum RBColor <Black Red>;
my class RBNode {
    has $.key;
    has $.value is rw;
    has RBColor $!color;

    has RBNode $.left is rw;
    has RBNode $.right is rw;
    has RBNode $.parent is rw; # XXX temporary

    submethod BUILD(:$!key!, :$!value!, :$!color = RBColor::Red) {}

    method color is rw { self.defined ?? $!color !! RBColor::Black }

    method is-black { $.color == RBColor::Black }
    method is-red   { $.color == RBColor::Red   }

    method blacken { $!color = RBColor::Black }
    method redden  { $!color = RBColor::Red   }
}

my $*RB_DEBUG = False;

my sub debug($msg) {
    say $msg if $*RB_DEBUG;
}

class RedBlackTree {
    has RBNode $!root;
    has &!cmp;

    submethod BUILD(:&!cmp = &[before]) {}

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

    method insert($key, $value) {
        # condition 1 (a node is either red or black) is satisified by
        # the type system

        POST {
            $!root.is-black
        }

        # condition 3 (all leaves are black) is satisified by the type
        # system (all undefined RBNodes are black)

        POST {
            # all red nodes have two black children
            self!check-nodes({
                $^node.is-black || ($^node.left.is-black && $^node.right.is-black)
            })
        }

        POST {
            # every path from a node to a leaf must contain
            # the same number of black nodes
            my $num-black-nodes;
            my $ok = True;
            for self!paths($!root) -> $path {
                debug $path.grep(*.is-black).map(*.key).join(' ');
                my $black-count = $path.grep({ $^n.is-black }).elems;

                $num-black-nodes = $black-count unless $num-black-nodes.defined;
                unless $num-black-nodes == $black-count {
                    say "oh shit: $num-black-nodes vs $black-count";
                    $ok = False;
                    last;
                }
            }
            $ok
        }

        my sub rotate-left(RBNode $node) {
            die "no right child for left rotation" unless $node.right;

            my $parent = $node.parent;

            my $node_cont;

            if $parent {
                $node_cont := $node === $parent.left ?? $parent.left !! $parent.right;
            } else {
                $node_cont := $!root;
            }

            $node_cont         = $node.right;
            $node_cont.parent  = $parent;

            $node.right        = $node_cont.left;
            $node.right.parent = $node if $node.right;

            $node_cont.left    = $node;
            $node.parent       = $node_cont;
        }

        my sub rotate-right(RBNode $node) {
            die "no left child for right rotation" unless $node.left;

            my $parent = $node.parent;

            my $node_cont;

            if $parent {
                $node_cont := $node === $parent.left ?? $parent.left !! $parent.right;
            } else {
                $node_cont := $!root;
            }

            $node_cont        = $node.left;
            $node_cont.parent = $parent;

            $node.left        = $node_cont.right;
            $node.left.parent = $node if $node.left;

            $node_cont.right = $node;
            $node.parent     = $node_cont;
        }

        my sub grandparent(RBNode $node) returns RBNode {
            my $parent = $node.parent;

            $parent ?? $parent.parent !! RBNode
        }

        my sub uncle(RBNode $node) returns RBNode {
            my $g      = grandparent($node);
            my $parent = $node.parent;

            if $g {
                $parent === $g.left ?? $g.right !! $g.left
            } else {
                RBNode
            }
        }

        my sub insert-case1(RBNode $node) {
            my $parent = $node.parent;

            if !$parent {
                debug "insert case #1";
                $node.blacken;
            } else {
                insert-case2($node);
            }
        }

        my sub insert-case2(RBNode $node) {
            my $parent = $node.parent;

            if $parent.is-black {
                debug "insert case #2";
                return;
            } else {
                insert-case3($node);
            }
        }

        my sub insert-case3(RBNode $node) {
            my $uncle = uncle($node);

            if $uncle.is-red {
                debug "insert case #3";
                $node.parent.blacken;
                $uncle.blacken;
                my $g = grandparent($node);
                $g.redden;
                insert-case1($g);
            } else {
                insert-case4($node);
            }
        }

        my sub insert-case4(RBNode $node is copy) {
            my $g = grandparent($node);

            if $node === $node.parent.right && $node.parent === $g.left {
                debug "insert case #4.1";
                rotate-left($node.parent);
                $node .= left;
            } elsif $node === $node.parent.left && $node.parent === $g.right {
                debug "insert case #4.2";
                rotate-right($node.parent);
                $node .= right;
            }
            insert-case5($node);
        }

        my sub insert-case5(RBNode $node) {
            my $g = grandparent($node);

            $node.parent.blacken;
            #say $node.key;
            #say self.dump;
            $g.redden;

            if $node === $node.parent.left {
                rotate-right($g);
            } else {
                rotate-left($g);
            }
        }

        my sub insert-helper(RBNode $parent is rw, RBNode $node) {
            if !$parent.defined {
                $parent = $node;
                debug 'insert:';
                debug self.dump;
            } else {
                $node.parent = $parent; # XXX lots of redundant writing here
                if &!cmp($node.key, $parent.key) {
                    insert-helper($parent.left, $node);
                } else {
                    insert-helper($parent.right, $node);
                }

                if $node.parent === $parent {
                    insert-case1($node);
                }
            }
        }

        debug 'before:';
        debug self.dump;
        if $!root {
            insert-helper($!root, RBNode.new(
                :$key,
                :$value,
            ));
        } else {
            $!root = RBNode.new(
                :$key,
                :$value,
                :color(RBColor::Black),
            );
        }
        debug 'after:';
        debug self.dump;
    }

    method dump {
        my sub dump-node(RBNode $node, $indent) returns Str {
            return ' ' x $indent ~ "(nil)\n" if !$node.defined;

            my $dump = ' ' x $indent ~ "$node.key() $node.value() ($node.color())\n";
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
}
