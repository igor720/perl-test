package PerlTest::LogParser 0.001;

# Можно было бы использовать DBI::DBx, но это как из пушки по воробьям
use parent qw(Exporter);
use DBI;
use DBD::Pg qw(:pg_types);

use strict;
use warnings;

our @EXPORT = qw(parse);

# Чтобы убыстрить вставку можно еще использовать bulk insert
my $SQL_MES = <<'SQL_MES';
    INSERT INTO message VALUES
    (TO_TIMESTAMP(?, 'YYYY-MM-DD HH24:MI:SS')::timestamp without time zone,
    ?, ?, ?, ?)
SQL_MES

my $SQL_LOG = <<'SQL_LOG';
    INSERT INTO log VALUES
    (TO_TIMESTAMP(?, 'YYYY-MM-DD HH24:MI:SS')::timestamp without time zone,
    ?, ?, ?)
SQL_LOG

sub parse {
    my $dbh = shift;
    my $insertion_speed = shift;
    my $count = 0;

    my $sth_mes = $dbh->prepare($SQL_MES);
    my $sth_log = $dbh->prepare($SQL_LOG);

    # следующие строки только для отладки
    my $sth_mes_trunc = $dbh->prepare("TRUNCATE message");
    my $sth_log_trunc = $dbh->prepare("TRUNCATE log");
    $sth_mes_trunc->execute() or die $DBI::errstr;
    $sth_log_trunc->execute() or die $DBI::errstr;
    $dbh->commit();

    while (<>) {
        # s/^\w+//;  # эта строка вроде не нужна для такого лога
        s/\s+$//;
        die "incorrect log entry"
            unless /^(\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d) (\S*) (\S*) *(.*)$/;
        my ($datetime, $int_id, $flag) = ($1, $2, $3);
        my $rest = $4;
        # пропускаем строки с общей информацией
        next unless $flag =~ /<=|=>|==|->|\*\*/;

        if ($flag eq "<=") {
            if ($rest !~ /id=(\S+)/) {
                # warn "field 'id' is not found in $rest\n"
                # похоже, что не все строки с флагом '<=' имеют поле 'id',
                # а между тем в базе данных это поле NOT NULL
            }
            else {
                $sth_mes->execute(
                    $datetime, $1, $int_id, "$int_id $flag $rest", undef
                    ) or die $DBI::errstr;
            }
        }
        else {
            die "field 'address' is not found in $rest\n"
                unless ($rest =~ /^(\S+)/);
            $sth_log->execute(
                $datetime, $int_id, "$int_id $flag $rest", $1
                ) or die $DBI::errstr;
        }
        $count++;
        $dbh->commit() if ($count % ($insertion_speed>0?$insertion_speed:1))==0;
        # last if $i>10;
    };
    $dbh->commit();
    return $count;
}

sub get_dbh {
    # my @driver_names = DBI->available_drivers;
    # print @driver_names;
    # my %drivers      = DBI->installed_drivers;
    # print %drivers;
    # my @data_sources = DBI->data_sources($driver_name, {});
    # print @data_sources;

    # my @data_sources = DBI->data_sources('Pg');
    # my @data_sources = $dbh->data_sources();
    # print "@data_sources";

    my $dbh = DBI->connect('dbi:Pg:dbname=test', '', '', {});

    my $ary_ref = $dbh->selectall_arrayref("SELECT id FROM message LIMIT 1");

    print "ary_ref = @$ary_ref\n";

    my $rc  = $dbh->disconnect;
}


return 1;



