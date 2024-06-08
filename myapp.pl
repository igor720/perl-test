#!/usr/bin/env perl
BEGIN {
    push (@INC, ".");
}

use Mojolicious::Lite -signatures;
use PerlTest::LogParser 0.001 qw(address_records);

my $dbh = DBI->connect(
    'dbi:Pg:dbname=test', '', '', {RaiseError => 1, AutoCommit => 0}
    );


get '/' => sub ($c) {
    $c->render(template => 'index');
};

# /foo1?addr=sri
get '/foo1' => sub ($c) {
    my $user = $c->param('user');
    # my @rows = (1,2,3,4,5);

    my $addr = 'ldtyzggfqejxo@mail.ru';

    my $rows = address_records ($dbh, $addr);

    $c->app->log->debug(@{$rows});

    $c->render(template => 'listing', rows => $rows);

    # $c->render(text => "Hello $user.");
};
    # <td>Cell <%= $n %></td><td><%= $n %></td>


app->start;
__DATA__

@@ listing.html.ep
% layout 'default';
% title 'DB Listing';
<table>
    <tr><th>Log</th></tr>
    % for my $r (@$rows) {
    <tr>
        % for my $f (@$r) {
        <td><%= $f %></td>
        % }
    </tr>
    % }
</table>

@@ index.html.ep
% layout 'default';
% title 'Welcome';
<h1>Welcome to the Mojolicious real-time web framework!</h1>


@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>



