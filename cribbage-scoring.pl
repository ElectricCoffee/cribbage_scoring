#!/usr/bin/env/perl

use v5.28;
use warnings;
use autodie;
no warnings 'experimental::smartmatch';
use List::Util qw(reduce sum);

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

package Card {
    use Carp;
    use overload '""' => \&to_str; # enables string interpolation

    sub new {
        my $class = shift;
        my %args = @_;
        bless {%args}, $class;
    }

    sub from_str {
        my $class = shift;
        my $str = shift;

        my $suit;
        my $value;

        given ($str) {
            when (m/([chsd])(a|10|\d|[jqk])/i) {
                $suit  = $1; 
                $value = $2;
            }

            when (m/(a|10|\d|[jqk])([chsd])/i) {
                $suit  = $2; 
                $value = $1;
            }

            when (m/(ace|10|\d|jack|queen|king) of (clubs|hearts|spades|diamonds)/i) {
                $suit  = substr($2, 0, 1); # just grab the first letter
                $value = $1;
                $value = substr($value, 0, 1) unless $value =~ m/\d+/;
            }

            default {
                croak "Did not understand the string $str. Format must be either SV or Value of Suit.";
            }
        }

        return $class->new(suit => $suit, value => $value);
    }

    sub to_str() {
        my $this = shift;

        my $suit;
        my $value;

        given ($this->suit) {
            $suit = 'Clubs'    when m/c/i;
            $suit = 'Hearts'   when m/h/i;
            $suit = 'Spades'   when m/s/i;
            $suit = 'Diamonds' when m/d/i;
            default {
                croak "Did not recognise the suit $_.";
            }
        }

        given ($this->value) {
            $value = $_      when m/\d+/i;
            $value = 'Ace'   when m/a/i;
            $value = 'Jack'  when m/j/i;
            $value = 'Queen' when m/q/i;
            $value = 'King'  when m/k/i;
            default {
                croak "Did not recognise the value $_.";
            }
        }

        return "$value of $suit";
    }

    # id gets a short string form of the card for easy comparison.
    sub id() {
        my $this = shift;
        return $this->value . $this->suit;
    }

    sub suit()  { shift->{suit}  }
    sub value() { shift->{value} }

    # Valuate gets the numerical value of a card
    #   A = 1
    #   # = #
    # JQK = 10
    sub valuate() {
        given (shift->value) {
            return 1  when m/\ba\b/i;
            return $_ when m/\b[2-9]\b/i;
            return 10 when m/\b10|[jqk]\b/i;

            default {
                croak "The value $_ is not a valid card value";
            }
        }
    }
}

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