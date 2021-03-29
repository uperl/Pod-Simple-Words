# Pod::Simple::Words ![linux](https://github.com/uperl/Pod-Simple-Words/workflows/linux/badge.svg) ![windows](https://github.com/uperl/Pod-Simple-Words/workflows/windows/badge.svg) ![macos](https://github.com/uperl/Pod-Simple-Words/workflows/macos/badge.svg) ![cygwin](https://github.com/uperl/Pod-Simple-Words/workflows/cygwin/badge.svg) ![msys2-mingw](https://github.com/uperl/Pod-Simple-Words/workflows/msys2-mingw/badge.svg)

Parse words and locations from a POD document

# SYNOPSIS

```perl
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
```

# DESCRIPTION

This [Pod::Simple](https://metacpan.org/pod/Pod::Simple) parser extracts words from POD, with location information.
Some other event types are supported for convenience.  The intention is to feed
this into a spell checker.  Note:

- stopwords

    This module recognizes inlined stopwords.  These are words that shouldn't be
    considered misspelled for the POD document.

- head1 is normalized to lowercase

    Since the convention is to uppercase `=head1` elements in POD, and most spell
    checkers consider this a spelling error, we convert `=head1` elements to lower
    case.

- comments in verbatim blocks

    Comments are extracted from verbatim blocks and their words are included,
    because misspelled words in the synopsis comments can be embarrassing!

- unicode

    Should correctly handle unicode, if the `=encoding` directive is correctly
    set.

# CONSTRUCTOR

## new

```perl
my $parser = Pod::Simple::Words->new;
```

This creates an instance of the parser.

# PROPERTIES

## callback

```perl
$parser->callback(sub {
  my($type, $filename, $line, $input) = @_;
  ...
});
```

This defines the callback when the specific input items are found.  Types:

- word

    Regular human language word.

- stopword

    Word that should not be considered misspelled.  This is often for technical
    jargon which is spelled correctly but not in the regular human language
    dictionary.

- module

    CPAN Perl module.  Of the form `Foo::Bar`.  As a special case `Foo::Bar's`
    is recognized as the possessive of the `Foo::Bar` module.

- url\_link

    A regular internet URL link.

- pod\_link

    A link to another POD document.  Usually a module or a script.

- error

    An error that was detected during parsing.  This allows the spell checker
    to check the correctness of the POD at the same time if it so chooses.

# SEE ALSO

- [Pod::Spell](https://metacpan.org/pod/Pod::Spell)

    and other modules do similar parsing of POD for potentially misspelled words.  At least
    internally.  The usually explicitly exclude comments from verbatim blocks, and often
    split words on the wrong boundaries.

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
