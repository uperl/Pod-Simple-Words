package Pod::Simple::Words;

use strict;
use warnings;
use 5.026;
use experimental qw( signatures );
use JSON::MaybeXS qw( encode_json );
use base qw( Pod::Simple );

# ABSTRACT: Parse words and locations from a POD document
# VERSION

=head1 SYNOPSIS

 # TODO

=head1 DESCRIPTION

This L<Pod::Simple> parser extracts words from POD, with location information.
The intention is to feed this into a spell checker.

=cut

__PACKAGE__->_accessorize(
  qw( line_number in_verbatim callback ),
);

=head1 CONSTRUCTOR

=head2 new

 my $parser = Pod::Simple::Words->new;

=cut

sub new ($class)
{
  my $self = $class->SUPER::new;
  $self->preserve_whitespace(1);
  $self->callback(sub {
    my $row = encode_json \@_;
    print "--- $row\n";
  });
  $self->in_verbatim(0);
  $self;
}

sub _handle_element_start ($self, $tagname, $attrhash, @)
{
  if($tagname eq 'L')
  {
    # TODO
  }
  $self->line_number($attrhash->{start_line}) if defined $attrhash->{start_line};
  $self->in_verbatim($self->in_verbatim+1)    if $tagname eq 'Verbatim';
  ();
}

sub _handle_element_end ($self, $tagname, @)
{
  $self->in_verbatim($self->in_verbatim-1) if $tagname eq 'Verbatim';
}

sub _add_words ($self, $line)
{
  foreach my $frag (split /\s/, $line)
  {
    next unless $frag =~ /\w/;
    $DB::single = 1;
    if($frag =~ /^[a-z']+::([a-z']+(::[a-z']+)*)$/i)
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

sub _handle_text ($self, $text)
{
  if($self->in_verbatim)
  {
    # TODO: parse comments only
  }
  else
  {
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
