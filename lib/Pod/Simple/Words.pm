package Pod::Simple::Words;

use strict;
use warnings;
use 5.022;
use experimental qw( signatures postderef );
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
  qw( line_number in_verbatim words ),
);

=head1 CONSTRUCTOR

=head2 new

 my $parser = Pod::Simple::Words->new;

=cut

sub new ($class)
{
  my $self = $class->SUPER::new;
  $self->preserve_whitespace(1);
  $self->words([]);
  $self->in_verbatim(0);
  $self;
}

sub _handle_element_start ($self, $tagname, $attrhash, @)
{
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
  foreach my $word (split /\b{wb}/, $line)
  {
    next unless $word =~ /\w/;
    push $self->words->@*, [ $self->source_filename, $self->line_number, $word ];
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


