#!/usr/bin/env/perl

use lib './modules';

use v5.28;
use warnings;
use autodie;
no warnings 'experimental::smartmatch';
use List::Util qw(reduce sum all);

use Card;

use constant {
    SCORE_FIFTEEN => 2,
    SCORE_PAIR    => 2,
    SCORE_TRIPLET => 6,
    SCORE_QUAD    => 12,
    SCORE_FLUSH4  => 4,
    SCORE_FLUSH5  => 5,
    SCORE_NOB     => 1,
};

=head1 Powerset
Creates a powerset from an array reference.
This code was lifted off of Rosetta Code
=cut
sub powerset {
    @_ ? map { $_, [$_[0], @$_] } powerset(@_[1..$#_]) : [];
}

=head1 Is Fifteen
Checks if one given hand adds up to 15
=cut
sub is_fifteen {
    sum(map { $_->valuate } @_) == 15
}

=head1 Check Fifteen
Finds every possible way to make 15 from a hand of cards
=cut
sub check_fifteen {
    my @result;

    for my $set (powerset(@_)) {
        if (@$set && is_fifteen(@$set)) {
            push @result, $set;
        }
    }

    @result;
}

=head1 Is Run
Checks if a given set of cards is a run.
Runs are defined by a given ordering of cards being 1 off from each other.
Also known as Straights in Poker
=cut
sub is_run {
    return 0 if @_ < 3; # runs can only be 3 or longer;

    my @ordered = sort { $a <=> $b } @_;
    my $last_card;

    for my $card (@ordered) {
        next unless defined $last_card;
        return 0 if $card->rank_order - $last_card->rank_order != 1;
    } continue {
        $last_card = $card; 
    }

    return 1;
}

=head1 Same Cards
Checks if the cards are the same given some criterium.
The criterium is supplied as a block.
For example, `same_cards { $_->suit } @cards` will check if all the cards share suit.
=cut
sub same_cards(&@) {
    my $func = shift;
    my @cards = map $func->($_), @_;
    return 0 unless @cards;

    all { $cards[0] eq $_ } @cards;
}

=head1 Is Pair
Checks if a given number of cards are a pair
=cut
sub is_pair {
    @_ == 2 && same_cards { $_->rank } @_;
}

=head1 Is Triplet
Checks if a given number of cards are a triplet (three of a kind)
=cut
sub is_triplet {
    @_ == 3 && same_cards { $_->rank } @_;
}

=head1 Is Quad
Checks if a given number of cards are a quad (four of a kind)
=cut
sub is_quad {
    @_ == 4 && same_cards { $_->rank } @_;
}

sub check_pair {
    my @result;

    for my $set (powerset(@_)) {
        push @result, $set if is_pair @$set;
    }
    @result;
}

sub check_triplet {} # should be included in pair?

sub check_quad {} # should be included in pair?

sub check_flush {
    my @hand = @{+shift};
    my $starter = shift;

    if (same_cards { $_->suit } (@hand, $starter)) {
        return (@hand, $starter);
    } elsif (same_cards { $_->suit } @hand) {
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

        push @fifteens, $set    if is_fifteen @$set;
        push @pairs, $set       if is_pair @$set;
        push @triplets, $set    if is_triplet @$set;
        push @quads, $set       if is_quad @$set;
        push @runs, $set        if is_run @$set;
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
say "@run is a run" if is_run @run;
say "@run is not a run" unless is_run @run;