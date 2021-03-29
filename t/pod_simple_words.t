use Test2::V0 -no_srand => 1;
use Pod::Simple::Words;
use Path::Tiny qw( path );


subtest 'basic' => sub {

  my $parser = Pod::Simple::Words->new;
  isa_ok 'Pod::Simple::Words';
  isa_ok 'Pod::Simple';

  my %actual;

  $parser->callback(sub {
    my($type, $file, $ln, $word) = @_;
    next unless $type eq 'word';
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

done_testing;


