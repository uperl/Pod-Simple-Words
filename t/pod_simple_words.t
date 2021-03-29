use Test2::V0 -no_srand => 1;
use Pod::Simple::Words;
use YAML qw( Dump );

subtest 'basic' => sub {

  my $parser = Pod::Simple::Words->new;
  isa_ok 'Pod::Simple::Words';
  isa_ok 'Pod::Simple';
  $parser->parse_file('corpus/Foo.pm');

  note Dump($parser->words);

};

done_testing;


