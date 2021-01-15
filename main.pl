#!/usr/bin/env/perl

use lib './modules';

use v5.28;
use warnings;
use autodie;

use Card;
use Subset;
use Util;
use List::Util qw(sum);

use constant {
    SCORE_FIFTEEN => 2,
    SCORE_PAIR    => 2,
    SCORE_TRIPLET => 6,
    SCORE_QUAD    => 12,
    SCORE_NOB     => 1,
};

=head1 Check Flush
Checks if a set contains a flush and extracts a copy of it.
If no flush is present, then an empty list is returned.
=cut
sub check_flush {
    my @hand = @{+shift};
    my $starter = shift;

    if (Util::same_cards { $_->suit } @hand) {
        if ($hand[0]->suit eq $starter->suit) {
            return (@hand, $starter);
        }
        
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

=head1 Check Hand
Goes through the entire hand and the starter and checks it for all point scoring features.
It then returns a hash containing its findings
=cut
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

    my @power_set = Util::powerset(@$hand, $starter);

    for my $set (sort { @$b <=> @$a } @power_set) {
        next if @$set < 2; # just skip the sets with fewer than 2 cards

        push @fifteens, $set    if Subset::is_fifteen(@$set);
        push @quads, $set       if Subset::is_quad(@$set);

        push @triplets, $set    
            if Subset::is_triplet(@$set)
            && !Util::subset_of_any($set, @quads);
        push @pairs, $set
            if Subset::is_pair(@$set) 
            && (!Util::subset_of_any($set, @quads) || !Util::subset_of_any($set, @triplets));

        push @runs, $set 
            if (Subset::is_run(@$set) 
            && !Util::subset_of_any($set, @runs))
    }

    my %result;
    $result{fifteens} = \@fifteens  if @fifteens;
    $result{pairs} = \@pairs        if @pairs;
    $result{triplets} = \@triplets  if @triplets;
    $result{quads} = \@quads        if @quads;
    $result{runs} = \@runs          if @runs;
    $result{flush} = \@flush        if @flush;
    $result{nob} = $nob             if $nob;

    #say Dumper(\%result);
    %result;
}

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
    my $key = shift;
    my $value = shift;
    my %result = @_;
    
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

    say "$count $key ($repr) totalling ", $score;
}

my @hand = map { Card->from_str($_) } qw(C4 H4 SA HJ);

my $top_card = Card->from_str('H7');

say "given a hand containing @{[@hand, $top_card]}:";

my %result = check_hand(\@hand, $top_card);

print_scores('fifteens', SCORE_FIFTEEN, %result);
print_scores('pairs', SCORE_PAIR, %result);
print_scores('triplets', SCORE_TRIPLET, %result);
print_scores('quads', SCORE_QUAD, %result);
print_scores('runs', 'COUNT', %result);

__END__
=head1 Ideas and Optimisations
=head2 Single Traversal
Order the powerset by length, so that you always start with the longest sets.
Then, progress through the algorithm as normal, but then check if the shorter sets are part of the longer ones.
If they are, don't include them in the list.

This has the obvious benefit of simply not having to filter out the duplicate entries after the fact, as they simply aren't included in the first place.
=cut