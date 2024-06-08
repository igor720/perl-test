package PerlTest::LogParser 0.001;

# Можно было бы использовать DBI::DBx, но это как из пушки по воробьям
use parent qw(Exporter);
use DBI;
use DBD::Pg qw(:pg_types);

use strict;
use warnings;

our @EXPORT = qw(parse address_records);

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

    # если есть вероятность, что транзакции обломятся, то надо исправить скрипт
    # и удалить имеющиеся записи после первоначальной в файле лога.
    # но в этой программе такая функциональность не предусмотрена.

    # имя файла лога берем из командной строки
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
            unless ($rest =~ /^(\S+)/) {
                warn "field 'address' is not found in $rest\n";
            }
            else {
                $sth_log->execute(
                    $datetime, $int_id, "$int_id $flag $rest", $1
                    ) or die $DBI::errstr;
            }
        }
        $count++;
        $dbh->commit() if ($count % ($insertion_speed>0?$insertion_speed:1))==0;
    };
    $dbh->commit();
    return $count;
}

my $SQL_RECORDS = <<'SQL_RECORDS';
    SELECT c, s FROM
    (((SELECT DISTINCT m.int_id as ii, m.created as c, m.str as s
        FROM message AS m INNER JOIN log AS l ON m.int_id=l.int_id
        WHERE l.address=$1)
    UNION
    (SELECT int_id as ii, created as c, str as s
        FROM log WHERE address=$1)
    ) ORDER BY ii, c LIMIT 101) AS foo;
SQL_RECORDS

sub address_records {
    my $dbh = shift;
    my $addr = shift;
    return $dbh->selectall_arrayref($SQL_RECORDS, {}, $addr);
}

return 1;



