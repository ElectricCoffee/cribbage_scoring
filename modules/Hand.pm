package Hand;
use Moo;

use v5.28;
use warnings;
use autodie;
no warnings 'experimental::smartmatch';
use Carp;
use Card;
use Data::Dumper;

has hand    => (is => 'ro');
has starter => (is => 'ro');

=head1 From String
Creates a new hand from a string.
TODO: Expand this code to make it more flexible.
=cut
sub from_str {
    my ($class, $str) = @_;
    my @parts = split( /\+/, $str);

    if (@parts < 2) {
        croak 'Input must consist of a hand + a starter, found less than that (', scalar @parts, ')';
    } elsif(@parts > 2) {
        croak 'Input must consist of only a hand + a starter, found more than that;'
    }
    
    chomp(my @lhs = split(/\s/, $parts[0]));
    chomp(my $starter = $parts[1]);

    croak 'Expected a hand of 4 cards, but got ', scalar @lhs if @lhs != 4;
    
    $class->new(
        hand    => [map { Card->from_str($_) } @lhs], 
        starter => Card->from_str($starter)
    );
}

=head1 Check Flush
Checks if a set contains a flush and extracts a copy of it.
If no flush is present, then an empty list is returned.
=cut
sub check_flush {
    my ($self) = @_;

    my @hand = $self->hand->@*;
    my $starter = $self->starter;

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
    my ($self) = @_;
    my @hand = $self->hand->@*;
    my $starter = $self->starter;

    grep { $_->rank =~ m/j/i && $_->suit eq $starter->suit } @hand;
}

=head1 Check Hand
Goes through the entire hand and the starter and checks it for all point scoring features.
It then returns a hash containing its findings
=cut
sub check {
    my ($self) = @_;

    my @fifteens;
    my @pairs;
    my @triplets;
    my @quads;
    my @runs;
    my @flush = $self->check_flush;
    my ($nob) = $self->check_nob;

    my @power_set = Util::powerset($self->hand->@*, $self->starter);

    for my $set (sort { @$b <=> @$a } @power_set) {
        next if @$set < 2; # just skip the sets with fewer than 2 cards

        push @fifteens, $set    if Subset::is_fifteen(@$set);
        push @quads, $set       if Subset::is_quad(@$set);

        push @triplets, $set    
            if Subset::is_triplet(@$set)
            && !Util::subset_of_any($set, @quads);

        push @pairs, $set
            if Subset::is_pair(@$set) 
            && !Util::subset_of_any($set, @quads) 
            && !Util::subset_of_any($set, @triplets);

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

1;