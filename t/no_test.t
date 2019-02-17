#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;
use Test::LongString;

use File::Spec;
use File::Basename;

use lib 'lib';
use lib '../lib';

## Webapp START

my $testdir = File::Spec->catdir( dirname(__FILE__), '..', 'test' );

plugin('Prove' => {
  route  => app->routes,
  prefix => 'prove2',
});

## Webapp END

my $t = Test::Mojo->new;

$t->get_ok( '/prove2/test/base/run' )->status_is( 200 );

my $content = $t->tx->res->body;
like_string $content, qr'<h2>Fehler</h2>';

done_testing();

