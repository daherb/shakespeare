use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use vars qw ($opt_w $opt_c $opt_s $opt_r $opt_n $opt_l $opt_d);
our $PROGNAME = "shakespeare.pl";
our %language_model;
sub HELP_MESSAGE
{
    print "Usage: perl $PROGNAME (-w|-c) (-s|-r filename)* (-n number)? -l count (-d percentage)? (filename)+\n";
    print "Generates random text from a language model\n";
    print "-w|-c: uses either word or character n-gramms for language model\n";
    print "-n: number for n of the n-gramms. Default is 3\n";
    print "-l: length of tokens (wither words or characters depending on -w|-c switch) to generate\n";
    print "-d: maximum deviation from the maximum likelihood\n";
    print "filenames: train on these files\n\n";
    exit(-1);
}

sub train
{
    print "training\n";
    my $tf;
    foreach my $f (@ARGV)
    {
	open($tf, '<', $f);
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
		$line =~ s/([.;:!?])/ $1 /g;
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
		$language_model{join '', @history}{$t}++;
		push(@history, $t);
		# Keep history to size n
		shift @history if ($#history > ( $opt_n - 2));
		print join('-', @history)."\n";
		# Clear after a sentence
		@history = () if ($t=~/([.;:!?])/);
	    }
	}
	close($tf);
    }
}

sub generate
{
    print Dumper(%language_model);
    print "generation\n";
}

sub store
{
    print "store\n";
}

sub load
{
    print "load\n";
}

# sub main
{
    # Check for command line arguments
    $Getopt::Std::STANDARD_HELP_VERSION = 1;
    if (( ! getopts('wcn:l:d:s:r:' ) ) or (! ((defined($opt_w) or defined($opt_c)) and defined($opt_l))))
    {
	HELP_MESSAGE;
    }
    # Step 0:
    # Set n if not already set
    our $opt_n = 3 if (! defined($opt_n) );
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
