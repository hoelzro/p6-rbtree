#!/usr/bin/env perl6

use v6;

use Test;
use RedBlackTree;

#plan 1;

{
    my @keys      = 6, 69, 65, 55, 89, 16, 51, 9, 27, 14;
    my @sorted    = @keys.sort;
    my @tree-wise = do gather {
        my $t = RedBlackTree.new;

        my $*RB_DEBUG = False;
        for @keys[0..9] -> $k {
            $t.insert($k, $k * $k);
        }

        for $t.keys -> $k {
            take $k;
        }
    };
    say @sorted.join(' ');
    say @tree-wise.join(' ');

    #is_deeply @sorted, @tree-wise;
}

# XXX removal
# XXX key cursor
