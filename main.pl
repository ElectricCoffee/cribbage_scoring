#!/usr/bin/env/perl

use lib './modules';

use v5.28;
use warnings;
use autodie;

use Card;
use Subset;
use Util;
use Hand;
use List::Util qw(sum);

use constant {
    SCORE_FIFTEEN => 2,
    SCORE_PAIR    => 2,
    SCORE_TRIPLET => 6,
    SCORE_QUAD    => 12,
    SCORE_NOB     => 1,
};

=head1 Print Scores
Prints the scores given by a hand, based upon a specific key.
It takes the following parameters:
=item $key
    which is one of the keys for the hash returned by check_hand
=item $value 
    which is the point value of each scored set, or the special value 'COUNT', which counts the cards.
=item %result
    which is the remainder of the argument list, containing all the results given by check_hand
=cut
sub print_scores {
    my ($key, $value, %result) = @_;
    
    return 0 unless defined $result{$key};

    if ($key eq 'nob') {
        say "Nobs ($result{$key}) for $value pt.";
        return $value;
    }

    # NB: each key stores an array ref of point scoring hands
    # this array ref needs to be unwrapped first.
    my @list_of_sets = $result{$key}->@*;

    my $count = @list_of_sets;
    my $repr = Util::stringify_sets @list_of_sets;

    my $score = $value eq 'COUNT' 
        ? sum map { scalar @$_ } @list_of_sets
        : $value * $count;

    say "$count $key: \n\t- $repr \ntotalling $score pt.";
    return $score;
}

my $hand = Hand->from_str("5H 4S 3D 4H + 5D");

my $hand_string = join ', ', $hand->hand->@*;

say "Given a hand containing $hand_string, and a(n) ", $hand->starter, ":";

my %result = $hand->check;

my %scoring = (
    fifteens    => SCORE_FIFTEEN,
    pairs       => SCORE_PAIR,
    triplets    => SCORE_TRIPLET,
    quads       => SCORE_QUAD,
    runs        => 'COUNT',
    flush       => 'COUNT',
    nob         => SCORE_NOB,
);

my $score;

for my $key (sort keys %scoring) {
    $score += print_scores($key, $scoring{$key}, %result);
}

say "Total score: $score pt.";

__END__
=head1 Ideas and Optimisations
=head2 Single Traversal
Order the powerset by length, so that you always start with the longest sets.
Then, progress through the algorithm as normal, but then check if the shorter sets are part of the longer ones.
If they are, don't include them in the list.

This has the obvious benefit of simply not having to filter out the duplicate entries after the fact, as they simply aren't included in the first place.
=cut