#!/usr/bin/env perl
BEGIN {
    push (@INC, ".");
}

use Mojolicious::Lite -signatures;
use PerlTest::LogParser 0.001 qw(address_records);

# Здесь мы могли бы предусмотреть файл конфигурации, но в данном простом случае
# обойдемся без него
use constant LIMIT => 100;
use constant DBNAME => 'test';

my $dbh = DBI->connect(
    'dbi:Pg:dbname='.DBNAME, '', '', {RaiseError => 1, AutoCommit => 1}
    );

get '/' => sub ($c) {
    my $addr = $c->param('addr');
    my $rows = address_records ($dbh, $addr);
    my $limitexceded = @{$rows}>LIMIT ? 1 : 0;
    $c->app->log->debug(@{$rows});
    $c->render(
        template => 'listing',
        rows => $rows,
        addr => $addr,
        limitexceded => $limitexceded);
};

app->start;
__DATA__

@@ listing.html.ep
% layout 'default';
% title 'DB Listing';
<div><form action="/">
  <label for="addr">Адрес:</label>
  <input type="text" id="addr" name="addr" value="<%= $addr %>">
  <input type="submit" value="Submit">
</form></div>
<br>
% if ($addr) {
    % if ($limitexceded) {
<div><span style="color:red">Лимит превышен!</span></div>
    % }
<br>
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
% }

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>



