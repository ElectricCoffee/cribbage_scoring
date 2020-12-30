#!/usr/bin/env/perl

use lib './modules';

use v5.28;
use warnings;
use autodie;
no warnings 'experimental::smartmatch';
use List::Util qw(reduce sum);

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


# lifted off of rosetta code
sub powerset {
    @_ ? map { $_, [$_[0], @$_] } powerset(@_[1..$#_]) : [];
}

=head1 Is Fifteen
Checks if one given hand adds up to 15
=cut
sub is_fifteen {
    sum(map { $_-> valuate } @_) == 15
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

=head1 Same Rank
Checks if all the cards in the given set share the same rank
=cut
sub same_rank {
    my @ranks = map { $_->value } @_;
    return 0 unless @ranks;

    @ranks == grep { $ranks[0] eq $_ } @ranks;
}

=head1 Same Suit
Checks if all the cards in the given set share the same suit
=cut
sub same_suit {
    my @suits = map { $_->suit } @_;
    return 0 unless @suits;

    @suits == grep { $suits[0] eq $_ } @suits;
}

=head1 Is Pair
Checks if a given number of cards are a pair
=cut
sub is_pair {
    @_ == 2 && same_rank @_;
}

=head1 Is Triplet
Checks if a given number of cards are a triplet (three of a kind)
=cut
sub is_triplet {
    @_ == 3 && same_rank @_;
}

=head1 Is Quad
Checks if a given number of cards are a quad (four of a kind)
=cut
sub is_quad {
    @_ == 4 && same_rank @_;
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

    if (same_suit(@hand, $starter)) {
        return (@hand, $starter);
    } elsif (same_suit(@hand)) {
        return @hand;
    } else {
        return ();
    }
}

my @hand = map { Card->from_str($_) } qw(C4 H4 SA HQ);

my $top_card = Card->from_str('C7');

my @results = check_fifteen(@hand, $top_card);
my @pairs = check_pair(@hand, $top_card);

say "given a hand containing @{[@hand, $top_card]}:";

for my $cards (@results) {
    local $" = ' + ';
    say "@$cards = 15";
}

for my $cards (@pairs) {
    local $" = ' and ';
    say "@$cards make a pair";
}