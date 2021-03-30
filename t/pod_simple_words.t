use Test2::V0 -no_srand => 1;
use 5.026;
use utf8;
use Pod::Simple::Words;
use Path::Tiny qw( path );
use Encode qw( encode );

subtest 'basic' => sub {

  my $parser = Pod::Simple::Words->new;
  isa_ok 'Pod::Simple::Words';
  isa_ok 'Pod::Simple';

  my %actual;

  $parser->callback(sub {
    my($type, $file, $ln, $word) = @_;
    return unless $type eq 'word';
    ok -f $file;
    $actual{$word} = {
      file => path($file)->basename,
      ln   => $ln,
    }
  });

  $parser->parse_file('corpus/Basic.pod');

  is
    \%actual,
    hash {
      field description => hash {
        field file => 'Basic.pod';
        field ln   => 1;
        end;
      };
      field very => hash {
        field file => 'Basic.pod';
        field ln   => 3;
        end;
      };
      field basic => hash {
        field file => 'Basic.pod';
        field ln   => 3;
        end;
      };
    },
  ;

};

subtest 'unicode' => sub {

  my $pod = <<~'POD';
    =encoding utf8

    =head1 DESCRIPTION

    In Russian we say Привет.

    =cut
    POD


  my $parser = Pod::Simple::Words->new;

  my %actual;

  $parser->callback(sub {
    my($type, undef, undef, $word) = @_;
    return unless $type eq 'word';
    $actual{$word}++;
  });

  $parser->parse_string_document(encode('UTF-8', $pod, Encode::FB_CROAK));

  is
    \%actual,
    hash {
      field description => 1;
      field In => 1;
      field Russian => 1;
      field we => 1;
      field say => 1;
      field 'Привет' => 1;
      end;
    },
  ;

};

subtest 'apostrophe' => sub {

  my $pod = <<~'POD';
    =encoding utf8

    =head1 DESCRIPTION

    Graham's Test.

    =cut
    POD


  my $parser = Pod::Simple::Words->new;

  my %actual;

  $parser->callback(sub {
    my($type, undef, undef, $word) = @_;
    return unless $type eq 'word';
    $actual{$word}++;
  });

  $parser->parse_string_document(encode('UTF-8', $pod, Encode::FB_CROAK));

  is
    \%actual,
    hash {
      field description => 1;
      field "Graham's" => 1;
      field Test => 1;
      end;
    },
  ;

};

subtest 'module apostrophe' => sub {

  my $pod = <<~'POD';
    =encoding utf8

    =head1 DESCRIPTION

    Foo::Bar::Baz's Test.

    =cut
    POD


  my $parser = Pod::Simple::Words->new;

  my %actual;

  $parser->callback(sub {
    my($type, undef, undef, $word) = @_;
    return unless $type eq 'module';
    $actual{$word}++;
  });

  $parser->parse_string_document(encode('UTF-8', $pod, Encode::FB_CROAK));

  is
    \%actual,
    { "Foo::Bar::Baz's" => 1 },
  ;

};

subtest 'module' => sub {

  my $pod = <<~'POD';
    =encoding utf8

    =head1 SEE ALSO

    =over 4

    =item FFI::Platypus

    =item YAML::XS

    =item Foo::Bar::Baz

    =back

    =cut
    POD


  my $parser = Pod::Simple::Words->new;

  my %actual;

  $parser->callback(sub {
    my($type, undef, undef, $word) = @_;
    return unless $type eq 'module';
    $actual{$word}++;
  });

  $parser->parse_string_document(encode('UTF-8', $pod, Encode::FB_CROAK));

  is
    \%actual,
    hash {
      field 'FFI::Platypus' => 1;
      field 'YAML::XS' => 1;
      field 'Foo::Bar::Baz' => 1;
      end;
    },
  ;

};

subtest 'stop words' => sub {
  my $pod = <<~'POD';
    =encoding utf8

    =begin stopwords

    frooble dabbo Привет

    =end stopwords

    =head1 DESCRIPTION

    huh

    =cut
    POD


  my $parser = Pod::Simple::Words->new;

  my %stop;
  my %actual;

  $parser->callback(sub {
    my($type, undef, undef, $word) = @_;
    if($type eq 'word')
    { $actual{$word}++ }
    elsif($type eq 'stopword')
    { $stop{$word}++ }
  });

  $parser->parse_string_document(encode('UTF-8', $pod, Encode::FB_CROAK));

  is
    \%actual,
    hash {
      field description => 1;
      field huh => 1;
      end;
    },
  ;

  is
    \%stop,
    { frooble => 1, dabbo => 1, 'Привет' => 1 },
  ;

};

subtest 'stop words (just for) ' => sub {
  my $pod = <<~'POD';
    =encoding utf8

    =for stopwords frooble dabbo Привет

    =head1 DESCRIPTION

    huh

    =cut
    POD


  my $parser = Pod::Simple::Words->new;

  my %actual;
  my %stop;

  $parser->callback(sub {
    my($type, undef, undef, $word) = @_;
    if($type eq 'word')
    { $actual{$word}++ }
    elsif($type eq 'stopword')
    { $stop{$word}++ }
  });

  $parser->parse_string_document(encode('UTF-8', $pod, Encode::FB_CROAK));

  is
    \%actual,
    hash {
      field description => 1;
      field huh => 1;
      end;
    },
  ;

  is
    \%stop,
    { frooble => 1, dabbo => 1, 'Привет' => 1 },
  ;

};

subtest 'comments in verbatim block' => sub {
  my $pod = <<~'POD';
    =encoding utf8

    =head1 NAME

    Foo::Bar::Baz - A Thing

    =head1 SYNOPSIS

     use strict;
     use warnings;
     say "Hello world!" # comment one
     exit;              # comment two

    =cut
    POD


  my $parser = Pod::Simple::Words->new;

  my %actual;

  $parser->callback(sub {
    my($type, undef, $ln, $word) = @_;
    return unless $type eq 'word';
    push $actual{$word}->@*, $ln;
  });

  $parser->parse_string_document(encode('UTF-8', $pod, Encode::FB_CROAK));

  is
    \%actual,
    {
      A => [5], name => [3], synopsis => [7], Thing => [5],
      comment => [11,12], one => [11], two => [12],
    },
  ;

};

subtest 'links' => sub {
  my $pod = <<~'POD';
    =head1 SEE ALSO

    =over 4

    =item L<some text|FFI::Platypus>

    =item L<the google|https://google.com>

    =item L<pod2yamlwords>

    =back

    =cut
    POD

  my $parser = Pod::Simple::Words->new;

  my %actual;
  my @links;

  $parser->callback(sub {
    my($type, undef, $ln, $word) = @_;
    if($type eq 'word')
    {
      $actual{$word}++;
    }
    elsif($type =~ /_link$/)
    {
      push @links, [$type, $ln, $word];
    }
  });

  $parser->parse_string_document(encode('UTF-8', $pod, Encode::FB_CROAK));

  is
    \%actual,
    { map { $_ => 1 } qw( see also some text the google pod2yamlwords ) },
  ;

  is
    \@links,
    [
      [ pod_link => 5, 'FFI::Platypus'      ],
      [ url_link => 7, 'https://google.com' ],
      [ pod_link => 9, 'pod2yamlwords'      ],
    ],
  ;

};

subtest 'errors' => sub {
  my $pod = <<~'POD';
    =head1 SEE ALSO

    =over 4

    =item one

    =item two

    =item three

    =cut
    POD

  my $parser = Pod::Simple::Words->new;

  my %actual;
  my $errors;

  $parser->callback(sub {
    my($type, undef, undef, $word) = @_;
    if($type eq 'word')
    {
      $actual{$word}++;
    }
    if($type eq 'error')
    {
      $errors++;
    }
  });

  $parser->parse_string_document(encode('UTF-8', $pod, Encode::FB_CROAK));

  is
    \%actual,
    { map { $_ => 1 } qw( see also one two three ) },
  ;

  ok $errors;
};

subtest 'para verbatim para' => sub {
  my $pod = <<~'POD';
    =head1 DESCRIPTION

    one

     say "hello world!\n"; # two

    three

    =cut
    POD

  my $parser = Pod::Simple::Words->new;

  my %actual;

  $parser->callback(sub {
    my($type, undef, $ln, $word) = @_;
    return unless $type eq 'word';
    $actual{$word} = [$ln];
  });

  $parser->parse_string_document(encode('UTF-8', $pod, Encode::FB_CROAK));

  is
    \%actual,
    { description => [1], one => [3], two => [5], three => [7] },
  ;
};

subtest 'verbatim without comment' => sub {
  my $pod = <<~'POD';
    =head1 DESCRIPTION

    one

     say "hello world!\n";

    two

    =cut
    POD

  my $parser = Pod::Simple::Words->new;

  my %actual;

  $parser->callback(sub {
    my($type, undef, $ln, $word) = @_;
    return unless $type eq 'word';
    $actual{$word} = [$ln];
  });

  $parser->parse_string_document(encode('UTF-8', $pod, Encode::FB_CROAK));

  is
    \%actual,
    { description => [1], one => [3], two => [7] },
  ;
};

subtest 'skip section' => sub {
  my $pod = <<~'POD';
    =head1 DESCRIPTION

    one

    =head1 CONTRIBUTORS

    foo bar baz

    =head1 SEE ALSO

    =over 4

    =item two

    =item three

    =item four

    =back

    =cut
    POD

  my $parser = Pod::Simple::Words->new;
  $parser->skip_sections('contributors');

  my %actual;

  $parser->callback(sub {
    my($type, undef, $ln, $word) = @_;
    return unless $type eq 'word';
    $actual{$word} = [$ln];
  });

  $parser->parse_string_document(encode('UTF-8', $pod, Encode::FB_CROAK));

  is
    \%actual,
    { description => [1], one => [3], contributors => [5], see => [9], also => [9], two => [13], three => [15], four => [17] },
  ;
};

done_testing;
