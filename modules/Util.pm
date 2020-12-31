package Util;

use v5.28;
use warnings;
use autodie;
use List::Util qw(all);

use Exporter 'import';

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

=head1 Powerset
Creates a powerset from an array reference.
This code was lifted off of Rosetta Code
=cut
sub powerset {
    @_ ? map { $_, [$_[0], @$_] } powerset(@_[1..$#_]) : [];
}

=head1 Is Subset
Checks if one array is a subset of another.
This code was lifted off of Ilmari Karonen's answer on Stack Overflow
=cut
sub is_subset {
    my ($small_set, $big_set) = @_;
    my %hash;

    undef @hash{@$small_set}; # set all keys to undef;
    # remove all the keys contained in the big set
    delete @hash{@$big_set}; 
    # if any remain, it means the small set contained things not in the big set
    return !%hash;
}

1;