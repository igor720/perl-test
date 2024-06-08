use Test::More;
use Mojo::File qw(curfile);
use Test::Mojo;

# Portably point to "../myapp.pl"
my $script = curfile->dirname->sibling('myapp.pl');

my $t = Test::Mojo->new($script);
$t->get_ok('/')->status_is(200)->content_like(qr/DB Listing/);

done_testing();
