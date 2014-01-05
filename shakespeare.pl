use strict;
use warnings;
use Getopt::Std;
use Storable qw (retrieve);
use Data::Dumper;
use utf8;
use open ':encoding(utf8)';
use v5.12;
use Encode;
use vars qw ($opt_w $opt_c $opt_s $opt_r $opt_n $opt_l $opt_t);
our $PROGNAME = "shakespeare.pl";
our $language_model;
sub HELP_MESSAGE
{
    print "Usage: perl $PROGNAME (-w|-c) (-s|-r filename)* (-n number)? -l count (-t candidates)? (filename)+\n";
    print "Generates random text from a language model\n";
    print "-w|-c: uses either word or character n-gramms for language model\n";
    print "-n: number for n of the n-gramms. Default is 3\n";
    print "-l: length of tokens (wither words or characters depending on -w|-c switch) to generate\n";
    print "-t: number of top candidates to be considered. Default is 10\n";
    print "filenames: train on these files\n\n";
    exit(-1);
}

sub train
{
    print "training\n";
    my $tf;
    foreach my $f (@ARGV)
    {
	open($tf, '< :raw', $f);
	my $line;
	my @history;
	while($line = <$tf>)
	{
	    chomp($line);
	    my @token;
	    # Read word n-grams
	    if ($opt_w)
	    {
		# Separate punctation characters and words with a space
#		$line =~ s/([.;:!?])/ $1 /g;
		$line =~ s/([\p{punct}])/ $1 /g;
		@token = split(/\s+/,$line);
		@token = map { "$_ "} @token;
	    }
	    # Read character n-grams
	    else
	    {
		@token = split(//,$line);
	    }
	    my $t;
	    foreach $t (@token)
	    {
		$$language_model{join '', @history}{$t}++;
		push(@history, $t);
		# Keep history to size n
		shift @history if ($#history > ( $opt_n - 2));
		# print join('-', @history)."\n";
		# Clear after a sentence
		@history = () if ($t=~/([.;:!?])/);
	    }
	}
	close($tf);
    }
#    print Dumper($language_model);
}

sub generate
{
#    print Dumper(%$language_model);
    print "generation\n";
    my $tokens = 0;
    my @history = ();
    my @text;
    my $token;
    my $max;
    while ($tokens < $opt_l)
    {
    	my $strhist = join '',@history;
    	my @candidates = sort {$$language_model{$strhist}{$b} <=> $$language_model{$strhist}{$a}} (keys $$language_model{$strhist} ) ;
    	$max = $opt_t-1;
    	$max = $#candidates-1 if ($#candidates <= $max);
    	my $t = int(rand($max));
#	print "$t - $max - $#candidates\n";
    	$token = $candidates[$t]; 
    	push @history, $token;
	push @text, $token;
        # Keep history to size n
    	shift @history if ($#history > ( $opt_n - 2));
    	# Clear after a sentence
    	@history = () if ($token=~/([.;:!?])/);
    	$tokens++;
#    	print Dumper(@history);
    }
    print join '',@text;
}

sub store
{
    print "store\n";
    Storable::store $language_model, $opt_s;
}

sub load
{
    print "load\n";
    $language_model = retrieve($opt_r);
}

# sub main
{
    # Check for command line arguments
    $Getopt::Std::STANDARD_HELP_VERSION = 1;
    if (( ! getopts('wcn:l:t:s:r:' ) ) or (! ((defined($opt_w) or defined($opt_c)) and defined($opt_l))))
    {
	HELP_MESSAGE;
    }
    # Step 0:
    # Set n and t if not already set
    our $opt_n = 3 if (! defined($opt_n) );
    our $opt_t = 10 if (! defined($opt_t) );
    # Step 1:
    # Load stored language model if given with switch -r
    load if defined($opt_r);
    # Step 2:
    # Train on additional text files given
    train if ($#ARGV >= 0);
    # Step 3:
    # Store new language model to a file if it is given with switch -s
    store if defined($opt_s);
    # Step 4:
    # Generate new text
    generate if ($opt_l != 0);
}
