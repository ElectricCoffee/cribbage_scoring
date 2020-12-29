#!/usr/bin/env/perl

use lib './modules';

use v5.28;
use warnings;
use autodie;
no warnings 'experimental::smartmatch';
use List::Util qw(reduce sum);

use Card;

use constant {
    FIFTEEN    => 2,
    PAIR       => 2,
    TRIPLET    => 6,
    QUAD       => 12,
    FLUSH4     => 4,
    FLUSH5     => 5,
    NOB        => 1,
    THIRTY_ONE => 2,
    GO         => 2,
};


# lifted off of rosetta code
sub powerset {
    @_ ? map { $_, [$_[0], @$_] } powerset(@_[1..$#_]) : [];
}

sub check_fifteen {
    my @result;

    for my $set (powerset(@_)) {
        if (@$set && sum(map { $_-> valuate } @$set) == 15) {
            push @result, $set;
        }
    }

    @result;
}

my @hand = map { Card->from_str($_) } qw(C4 H4 SA HQ);

my $top_card = Card->from_str('C7');

my @results = check_fifteen(@hand, $top_card);

say "given a hand containing @{[@hand, $top_card]}:";

for my $cards (@results) {
    local $" = ' + ';
    say "@$cards = 15";
}