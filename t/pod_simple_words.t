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
      field DESCRIPTION => hash {
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
      field DESCRIPTION => 1;
      field In => 1;
      field Russian => 1;
      field we => 1;
      field say => 1;
      field 'Привет' => 1;
      end;
    },
  ;

};

subtest 'apostrophy' => sub {

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
      field DESCRIPTION => 1;
      field "Graham's" => 1;
      field Test => 1;
      end;
    },
  ;

};

subtest 'module apostrophy' => sub {

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

done_testing;
