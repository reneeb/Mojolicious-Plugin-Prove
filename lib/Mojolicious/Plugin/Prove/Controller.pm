package Mojolicious::Plugin::Prove::Controller;

use Mojo::Base 'Mojolicious::Controller';

use App::Prove;
use Capture::Tiny qw(capture);
use File::Basename;
use File::Find::Rule;

our $VERSION = 0.09;

sub list {
    my $self = shift;
    
    my $conf = $self->stash->{conf};
    
    my $name = $self->param( 'name' );
    if ( $name && !exists $conf->{$name} ) {
        $self->render( 'prove_exception' );
        return;
    }
    
    if ( $name ) {
        my @files = File::Find::Rule->file->name( '*.t' )->maxdepth( 1 )->in( $conf->{$name} );
        $self->stash( files => [ map{ basename $_ }@files ] );
        $self->stash( names => '' );
    }
    else {
        $self->stash( name  => '' );
        $self->stash( names => [ keys %{$conf} ] );
        $self->stash( files => '' );
    }
    
    $self->render( 'prove_file_list' );
}

sub file {
    my $self = shift;
    
    my $file   = $self->param( 'file' );
    my $name   = $self->param( 'name' );

    $self->stash( format => 'html' );
    
    my $conf = $self->stash->{conf};
    
    if ( !exists $conf->{$name} ) {
        $self->render( 'prove_exception' );
        return;
    }
    
    my @files = File::Find::Rule->file->name( '*.t' )->maxdepth( 1 )->in( $conf->{$name} );
    
    my ($found) = grep{ $file eq basename $_ }@files;
        
    if ( !$found ) {
        $self->render( 'prove_exception' );
        return;
    }
    
    my $content = do{ local ( @ARGV,$/ ) = $found; <> };
    $self->stash( code => $content );
    $self->stash( file => $file );
    
    $self->render( 'prove_file' );
}

sub run {
    my $self = shift;
    
    my $file = $self->param( 'file' );
    my $name = $self->param( 'name' );
    
    my $conf = $self->stash->{conf};
    
    if ( !exists $conf->{$name} ) {
        $self->render( 'prove_exception' );
        return;
    }
    
    my @files = File::Find::Rule->file->name( '*.t' )->maxdepth( 1 )->in( $conf->{$name} );
    
    my $found;
    if ( $file ) {
        ($found) = grep{ $file eq basename $_ }@files;
        
        if ( !$found ) {
            $self->render( 'prove_exception' );
            return;
        }
    }
    
    my @args = $found ? $found : @files;
    @args    = sort @args;

    local $ENV{HARNESS_TIMER};

    my $accepts = $self->app->renderer->accepts( $self )->[0] // 'html';
    my $format  = $accepts =~ m{\Ahtml?} ? 'html' : $accepts;

    my $prove = App::Prove->new;

    $prove->process_args( '--norc', @args );
    $prove->formatter('TAP::Formatter::HTML') if $format eq 'html';

    my ($stdout, $stderr, @result) = capture {
        $prove->run;
    };
    
    if ( $format eq 'html' ) {
        $stdout =~ s{\A.*?^(<!DOCTYPE)}{$1}xms;
        $self->render( text => $stdout );
    }
    else {
        $self->tx->res->headers->content_type('text/plain');
        $self->render( text => $stdout );
    }
}

1;

=head1 METHODS

=head2 file

=head2 list

=head2 run

