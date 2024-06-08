#!/usr/bin/env perl
use Mojolicious::Lite -signatures;

BEGIN {
    push (@INC, ".");
}


get '/' => sub ($c) {
    $c->render(template => 'index');
};

# /foo1?user=sri
get '/foo1' => sub ($c) {
    my $user = $c->param('user');
    my @rows = (1,2,3,4,5);

    $c->app->log->debug("Request from ******************");

    $c->render(template => 'listing', rows => \@rows);

#     say $c->render(<<'EOF', { rows => \@rows } );
# % for (@$rows) {
# <%= "Row $_\n" =%>
# % }
# EOF

    # $c->render(text => "Hello $user.");
};


app->start;
__DATA__

@@ listing.html.ep
% layout 'default';
% title 'DB Listing';
<table>
   <tr><th>Heading 1</th><th>Heading 2</th></tr>
   % for my $n (@$rows) {
   <tr><td>Cell <%= $n %></td><td><%= $n %></td></tr>
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



