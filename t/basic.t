#!/usr/bin/env perl6

use v6;

use Test;
use RedBlackTree;

plan 2;

my $*RB-CHECK-INVARIANTS = True;

{
    my @keys      = 6, 69, 65, 55, 89, 16, 51, 9, 27, 14;
    my @sorted    = @keys.sort;
    my @tree-wise = do gather {
        my $t = RedBlackTree.new;

        my $*RB_DEBUG = False;
        for @keys -> $k {
            $t.insert($k, $k * $k);
        }

        for $t.keys -> $k {
            take $k;
        }
    };

    is_deeply @sorted, @tree-wise;
}

{
    my @keys      = 6, 69, 65, 55, 89, 16, 51, 9, 27, 14;
    my @sorted    = @keys.sort;
    my @tree-wise = do gather {
        my $t = RedBlackTree.new;

        my $*RB_DEBUG = False;
        for @keys -> $k {
            $t.insert($k, $k * $k);
        }

        for @keys[0, 2, 4...*] -> $k {
            $t.delete($k);
        }

        for $t.keys -> $k {
            take $k;
        }
    };

    is_deeply @sorted[1,3,5...*], @tree-wise;
}

# XXX removal
# XXX key cursor
# XXX duplicates (if we allow them, what about removing them?)
