package Subset;

use v5.28;
use warnings;
use autodie;
use List::Util qw(sum);

use Util;

=head1 Is Fifteen
Checks if one given hand adds up to 15
=cut
sub is_fifteen {
    sum(map { $_->valuate } @_) == 15
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

=head1 Is Pair
Checks if a given number of cards are a pair
=cut
sub is_pair {
    @_ == 2 && Util::same_cards { $_->rank } @_;
}

=head1 Is Triplet
Checks if a given number of cards are a triplet (three of a kind)
=cut
sub is_triplet {
    @_ == 3 && Util::same_cards { $_->rank } @_;
}

=head1 Is Quad
Checks if a given number of cards are a quad (four of a kind)
=cut
sub is_quad {
    @_ == 4 && Util::same_cards { $_->rank } @_;
}

1;