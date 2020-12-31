#!/usr/bin/env/perl

use lib './modules';

use v5.28;
use warnings;
use autodie;
no warnings 'experimental::smartmatch';
use List::Util qw(reduce sum all);

use Card;
use Subset;
use Util;

use constant {
    SCORE_FIFTEEN => 2,
    SCORE_PAIR    => 2,
    SCORE_TRIPLET => 6,
    SCORE_QUAD    => 12,
    SCORE_FLUSH4  => 4,
    SCORE_FLUSH5  => 5,
    SCORE_NOB     => 1,
};

=head1 Check Fifteen
Finds every possible way to make 15 from a hand of cards
=cut
sub check_fifteen {
    my @result;

    for my $set (Util::powerset(@_)) {
        if (@$set && Subset::is_fifteen(@$set)) {
            push @result, $set;
        }
    }

    @result;
}

sub check_pair {
    my @result;

    for my $set (Util::powerset(@_)) {
        push @result, $set if Subset::is_pair @$set;
    }
    @result;
}

sub check_flush {
    my @hand = @{+shift};
    my $starter = shift;

    if (Util::same_cards { $_->suit } (@hand, $starter)) {
        return (@hand, $starter);
    } elsif (Util::same_cards { $_->suit } @hand) {
        return @hand;
    } else {
        return ();
    }
}

=head1 Check Nob
Checks to see if the hand has a Nob in it.
I.e. a Jack of the same suit as the starter.
=cut
sub check_nob {
    my @hand = @{+shift};
    my $starter = shift;

    grep { $_->rank =~ m/j/i && $_->suit eq $starter->suit } @hand;
}

sub check_hand {
    my $hand = shift;
    my $starter = shift;

    my @fifteens;
    my @pairs;
    my @triplets;
    my @quads;
    my @runs;
    my @flush = check_flush $hand, $starter;
    my ($nob) = check_nob $hand, $starter;

    for my $set (powerset(@$hand, $starter)) {
        next if @$set < 2; # just skip the sets with fewer than 2 cards

        push @fifteens, $set    if Subset::is_fifteen @$set;
        push @pairs, $set       if Subset::is_pair @$set;
        push @triplets, $set    if Subset::is_triplet @$set;
        push @quads, $set       if Subset::is_quad @$set;
        push @runs, $set        if Subset::is_run @$set;
    }
}

my @hand = map { Card->from_str($_) } qw(C4 H4 SA HJ);

my $top_card = Card->from_str('H7');

my @results = check_fifteen(@hand, $top_card);
my @pairs = check_pair(@hand, $top_card);
my @nob = check_nob(\@hand, $top_card);

say "given a hand containing @{[@hand, $top_card]}:";

for my $cards (@results) {
    local $" = ' + ';
    say "@$cards = 15";
}

for my $cards (@pairs) {
    local $" = ' and ';
    say "@$cards make a pair";
}

say "The hand has @nob as a nob";

my @run = map { Card->from_str($_)} qw(HA H2 H3 H4);
say "@run is a run"     if Subset::is_run @run;
say "@run is not a run" unless Subset::is_run @run;