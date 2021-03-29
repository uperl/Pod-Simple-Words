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

done_testing;
