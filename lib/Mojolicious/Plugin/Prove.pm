package Mojolicious::Plugin::Prove;

# ABSTRACT: run test scripts via browser

use Mojo::Base 'Mojolicious::Plugin::Prove::Base';
use Mojo::File;

our $VERSION = 0.10;

sub register {
    my ($self, $app, $conf) = @_;
    
    # we need configuration hash that looks like
    # {
    #    prefix => 'prove',
    #    tests  => {
    #        name  => '/testdir',
    #        name2 => '/other/dir',
    #    }
    # }
    
    # Add template path
    $self->add_template_path($app->renderer, __PACKAGE__);
    
    # Add public path
    my $static_path = Mojo::File->new(__FILE__)->sibling('Prove', 'public' )->to_string;
    push @{ $app->static->paths }, $static_path;
    
    $app->plugin( 'PPI' => { no_check_file => 1 } );
    
    # Routes
    my $r      = $app->routes;
    $r         = $conf->{route}  if $conf->{route};
    my $prefix = $conf->{prefix} // 'prove';
    
    $self->prefix($prefix);
    $self->conf( $conf->{tests} || {} );
    
    
    {
        my $pr = $r->route("/$prefix")->to(
            'controller#',
            namespace => 'Mojolicious::Plugin::Prove',
            plugin    => $self,
            prefix    => $self->prefix,
            conf      => $self->conf,
        );
        
        $pr->get('/')->to( '#list' )->name('mpp_prove_list');
        $pr->get('/test/*name/file/*file/run')->to( '#run' )->name('mpp_run_file');
        $pr->get('/test/*name/file/*file')->to( '#file' )->name('mpp_file');
        $pr->get('/test/*name/run')->to( '#run' )->name('mpp_run_all');
        $pr->get('/test/*name')->to( '#list' )->name('mpp_file_list');
    }
}

1;

=head1 SYNOPSIS

  # Mojolicious::Lite
  plugin 'Prove' => {
      tests => {
          my_tests => '/path/to/test/files.t',
      },
  };

  # Mojolicious
  $app->plugin( 'Prove' => {
      tests => {
          my_tests => '/path/to/test/files.t',
      },
  });

  # Access
  http://localhost:3000/prove
  
  # Prefix
  plugin 'Prove' => {
      tests => {
          my_tests => '/path/to/test/files.t',
      },
      prefix => 'tests',
  };
