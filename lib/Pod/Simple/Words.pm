package Pod::Simple::Words;

use strict;
use warnings;
use 5.026;
use experimental qw( signatures );
use JSON::MaybeXS qw( encode_json );
use PPI;
use base qw( Pod::Simple );

# ABSTRACT: Parse words and locations from a POD document
# VERSION

=head1 SYNOPSIS

 use Pod::Simple::Words;

 my $parser = Pod::Simple::Words->new;

 $parser->callback(sub {
   my($type, $filename, $line, $input) = @_;

   if($type eq 'word')
   {
     # $input is human language word
   }
   elsif($type eq 'stopword')
   {
     # $input is a stopword in tech speak
   }
   elsif($type eq 'module')
   {
     # $input is CPAN moudle (eg FFI::Platypus)
   }
   elsif($type eq 'url_link')
   {
     # $input is a URL (eg https://metacpan.org)
   }
   elsif($type eq 'pod_link')
   {
     # $input is a link to POD (eg L<FFI::Platypus>)
   }
   elsif($type eq 'error')
   {
     # $input is a POD error
   }
 });

 $parser->parse_file('lib/Foo.pm');

=head1 DESCRIPTION

This L<Pod::Simple> parser extracts words from POD, with location information.
Some other event types are supported for convenience.  The intention is to feed
this into a spell checker.  Note:

=over 4

=item stopwords

This module recognizes inlined stopwords.  These are words that shouldn't be
considered misspelled for the POD document.

=item head1 is normalized to lowercase

Since the convention is to uppercase C<=head1> elements in POD, and most spell
checkers consider this a spelling error, we convert C<=head1> elements to lower
case.

=item comments in verbatim blocks

Comments are extracted from verbatim blocks and their words are included,
because misspelled words in the synopsis comments can be embarrassing!

=item unicode

Should correctly handle unicode, if the C<=encoding> directive is correctly
set.

=back

=cut

__PACKAGE__->_accessorize(
  qw( line_number in_verbatim in_head1 callback target ),
);

=head1 CONSTRUCTOR

=head2 new

 my $parser = Pod::Simple::Words->new;

This creates an instance of the parser.

=head1 PROPERTIES

=head2 callback

 $parser->callback(sub {
   my($type, $filename, $line, $input) = @_;
   ...
 });

This defines the callback when the specific input items are found.  Types:

=over 4

=item word

Regular human language word.

=item stopword

Word that should not be considered misspelled.  This is often for technical
jargon which is spelled correctly but not in the regular human language
dictionary.

=item module

CPAN Perl module.  Of the form C<Foo::Bar>.  As a special case C<Foo::Bar's>
is recognized as the possessive of the C<Foo::Bar> module.

=item url_link

A regular internet URL link.

=item pod_link

A link to another POD document.  Usually a module or a script.

=item error

An error that was detected during parsing.  This allows the spell checker
to check the correctness of the POD at the same time if it so chooses.

=back

=cut

sub new ($class)
{
  my $self = $class->SUPER::new;
  $self->preserve_whitespace(1);
  $self->in_verbatim(0);
  $self->in_head1(0);
  $self->no_errata_section(1);
  $self->accept_targets( qw( stopwords ));
  $self->target(undef);
  $self->callback(sub {
    my $row = encode_json \@_;
    print "--- $row\n";
  });
  $self;
}

sub _handle_element_start ($self, $tagname, $attrhash, @)
{
  $self->line_number($attrhash->{start_line}) if defined $attrhash->{start_line};

  if($tagname eq 'L')
  {
    my @row = ( $attrhash->{type} . "_link", $self->source_filename, $self->line_number, $attrhash->{to}.'' );
    $self->callback->(@row);
  }
  elsif($tagname eq 'for')
  {
    $self->target($attrhash->{target});
  }
  elsif($tagname eq 'Verbatim')
  {
    $self->in_verbatim($self->in_verbatim+1);
  }
  elsif($tagname eq 'head1')
  {
    $self->in_head1($self->in_head1+1);
  }
  ();
}

sub _handle_element_end ($self, $tagname, @)
{
  if($tagname eq 'Verbatim')
  {
    $self->in_verbatim($self->in_verbatim-1);
  }
  elsif($tagname eq 'head1')
  {
    $self->in_head1($self->in_head1-1);
  }
  elsif($tagname eq 'for')
  {
    $self->target(undef);
  }
}

sub _add_words ($self, $line)
{
  foreach my $frag (split /\s/, $line)
  {
    next unless $frag =~ /\w/;
    if($frag =~ /^[a-z]+::([a-z]+(::[a-z]+)*('s)?)$/i)
    {
      my @row = ( 'module', $self->source_filename, $self->line_number, $frag );
      $self->callback->(@row);
    }
    else
    {
      foreach my $word (split /\b{wb}/, $frag)
      {
        next unless $word =~ /\w/;
        my @row = ( 'word', $self->source_filename, $self->line_number, $word );
        $self->callback->(@row);
      }
    }
  }
}

sub whine ($self, $line, $complaint)
{
  my @row = ( 'error', $self->source_filename, $self->line_number, $complaint );
  $self->callback->(@row);
  $self->SUPER::whine($line, $complaint);
}

sub scream ($self, $line, $complaint)
{
  my @row = ( 'error', $self->source_filename, $self->line_number, $complaint );
  $self->callback->(@row);
  $self->SUPER::scream($line, $complaint);
}

sub _handle_text ($self, $text)
{
  if($self->target)
  {
    if($self->target eq 'stopwords')
    {
      foreach my $word (split /\b{wb}/, $text)
      {
        next unless $word =~ /\w/;
        my @row = ( 'stopword', $self->source_filename, $self->line_number, $word );
        $self->callback->(@row);
      }
    }
  }
  elsif($self->in_verbatim)
  {
    my $base_line = $self->line_number;
    my $doc = PPI::Document->new(\$text);
    foreach my $comment (($doc->find('PPI::Token::Comment') || [])->@*)
    {
      $self->line_number($base_line + $comment->location->[0] - 1);
      $self->_add_words("$comment");
    }
  }
  else
  {
    $text = lc $text if $self->in_head1;
    while($text =~ /^(.*?)\r?\n(.*)$/)
    {
      $text = $2;
      $self->_add_words($1);
      $self->line_number($self->line_number+1);
    }
    $self->_add_words($text);
  }
  ();
}

1;

=head1 SEE ALSO

=over 4

=item L<Pod::Spell>

and other modules do similar parsing of POD for potentially misspelled words.  At least
internally.  The usually explicitly exclude comments from verbatim blocks, and often
split words on the wrong boundaries.

=back
