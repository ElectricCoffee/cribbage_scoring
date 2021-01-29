package Card;
use Moo;

use v5.28;
use warnings;
use autodie;
no warnings 'experimental::smartmatch';
use Carp;

use overload 
    '""'  => \&to_str,  # enables string interpolation
    '<=>' => \&compare; # overloads the <=> operator and gives <, <=, ==, >=, and > for free

has suit => (is => 'ro');
has rank => (is => 'ro');

=head1 From Str
Converts a string to a Card object
=cut
sub from_str {
    my ($class, $str) = @_;

    my $suit;
    my $rank;

    given ($str) {
        when (m/([chsd])(a|10|\d|[jqk])/i) {
            $suit  = $1;
            $rank = $2;
        }

        when (m/(a|10|\d|[jqk])([chsd])/i) {
            $suit  = $2;
            $rank = $1;
        }

        when (m/(ace|10|\d|jack|queen|king) of (clubs|hearts|spades|diamonds)/i) {
            $suit  = substr($2, 0, 1); # just grab the first letter
            $rank = $1;
            $rank = substr($rank, 0, 1) unless $rank =~ m/\d+/;
        }

        default {
            croak "Did not understand the string $str. Format must be either SV or Rank of Suit.";
        }
    }

    return $class->new(suit => $suit, rank => $rank);
}

=head1 To Str
Converts the card object to a human readable string
=cut
sub to_str() {
    my ($this) = @_;

    my $suit;
    my $rank;

    given ($this->suit) {
        $suit = 'Clubs'    when m/c/i;
        $suit = 'Hearts'   when m/h/i;
        $suit = 'Spades'   when m/s/i;
        $suit = 'Diamonds' when m/d/i;
        default {
            croak "Did not recognise the suit $_.";
        }
    }

    given ($this->rank) {
        $rank = $_      when m/\d+/i;
        $rank = 'Ace'   when m/a/i;
        $rank = 'Jack'  when m/j/i;
        $rank = 'Queen' when m/q/i;
        $rank = 'King'  when m/k/i;
        default {
            croak "Did not recognise the rank $_.";
        }
    }

    return "$rank of $suit";
}

=head1 ID 
Gets a short string form of the card for easy comparison.
=cut
sub id() {
    my ($this) = @_;
    return $this->rank . $this->suit;
}

=head1 Valuate 
Gets the numerical value of a card
  A = 1
  # = #
JQK = 10
=cut
sub valuate() {
    given (shift->rank) {
        return 1  when m/\ba\b/i;
        return $_ when m/\b[2-9]\b/i;
        return 10 when m/\b10|[jqk]\b/i;

        default {
            croak "The rank $_ is not a valid card rank";
        }
    }
}

=head1 Rank Order
Helper function to determine rank ordering.
Note that this is not the same as getting the value of the order.
The value of a court card is always 10, but for the purpose of ordering, court cards are > 10
=cut
sub rank_order() {
    my ($this) = @_;

    given ($this->rank) {
        return 1 when m/a/i;
        return $_ when m/10|[2-9]/;
        return 11 when m/j/i;
        return 12 when m/q/i;
        return 13 when m/k/i;
        default {
            croak "Did not recognise the rank $_";
        }
    }
}

=head1 Compare
Compares the ranks of two cards, on a tie it compares the suits.
Returns -1, 0, or 1 like cmp normally does
=cut
sub compare {
    my ($this, $that) = @_;

    my $comparison = $this->rank_order <=> $that->rank_order;

    $comparison || ($this->suit cmp $that->suit);
}

1;