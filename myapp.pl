#!/usr/bin/env perl
use Mojolicious::Lite -signatures;

BEGIN {
    push (@INC, ".");
}


get '/' => sub ($c) {
  $c->render(template => 'index');
};

# /foo?user=sri
get '/foo1' => sub ($c) {
  my $user = $c->param('user');

  $c->app->log->debug("Request from ******************");

  $c->render(text => "Hello $user.");
};

get '/foo2' => sub ($c) {
  $c->stash(one => 23);
  $c->render(template => 'magic', two => 24);
};

# Access request information
get '/agent' => sub ($c) {
  my $host = $c->req->url->to_abs->host;
  my $ua   = $c->req->headers->user_agent;
  $c->render(text => "Request by $ua reached $host.");
};

# Echo the request body and send custom header with response
post '/echo' => sub ($c) {
  $c->res->headers->header('X-Bender' => 'Bite my shiny metal ass!');
  $c->render(data => $c->req->body);
};

# Not found (404)
get '/missing' => sub ($c) {
  $c->render(template => 'does_not_exist');
};

# Exception (500)
get '/dies' => sub { die 'Intentional error' };

get '/with_block' => 'block';

app->start;
__DATA__

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

@@ magic.html.ep
The magic numbers are <%= $one %> and <%= $two %>.

@@ block.html.ep
% my $link = begin
  % my ($url, $name) = @_;
  Try <%= link_to $url => begin %><%= $name %><% end %>.
% end
<!DOCTYPE html>
<html>
  <head><title>Sebastians frameworks</title></head>
  <body>
    %= $link->('http://mojolicious.org', 'Mojolicious')
    %= $link->('http://mojojs.org', 'mojo.js')
  </body>
</html>

