package Mojolicious::Plugin::Prove::Base;

use Mojo::Base 'Mojolicious::Plugin';

use Cwd 'abs_path';

has 'prefix';
has 'conf';

sub add_template_path {
  my ($self, $renderer, $class) = @_;
  
  $class  =~ s{::}{/}g;
  $class .= '.pm';
  
  my $public = abs_path $INC{$class};
  $public    =~ s/\.pm$//;
  
  push @{$renderer->paths}, "$public/templates";
}

1;
