#!/usr/bin/env perl

BEGIN {
    push (@INC, ".");
}

use DBI;
use DBD::Pg qw(:pg_types);
use PerlTest::LogParser 0.001 qw(parse);

# Здесь мы могли бы предусмотреть файл конфигурации, но в данном простом случае
# обойдемся без него
use constant DBNAME => 'test';

# отменяем AutoCommit, чтобы вставлять быстрее посредством транзакций
my $dbh = DBI->connect(
    'dbi:Pg:dbname='.DBNAME, '', '', {RaiseError => 1, AutoCommit => 0}
    );

my $insertion_speed = 1000; # >0, 1 для автокоммита
my $count = parse($dbh, $insertion_speed);

#print "count = $count";

1;
