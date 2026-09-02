package PTC::Device;

use strict;
use warnings;
use Exporter;
use PTC::Utils;
use Carp;

our @ISA = qw(Exporter);

our @EXPORT = qw(getPreviewMessage updateWLANnetMessage clearWLANnetMessage getWLANnetMessage getWLANnetClientMessage saveClientDevice  showHPNAAddress  loadHPNAClient checkRegister getHPNAPassword saveHPNAPassword addClient updateClient LANWORLD);






# Needs reason check
sub getWLANnetMessage
{
    my $username=shift;
    my $sth = $main::dbh_ptc->prepare("SELECT StartTime,ticket FROM blacklist WHERE UserName = ? AND StopTime = '0000-00-00 00:00:00' ;");
    $sth->execute($username);
    my @row;
    my %msg;
    while (@row = $sth->fetchrow_array ) {
        $msg{$row[0]}=$row[1];
    }
    return \%msg;
}

sub getPreviewMessage
{
    my $dbh=shift;
    my $sth = $dbh->prepare("SELECT StartTime,ticket FROM blacklist WHERE id=1 ;");
    $sth->execute();
    my @row;
    my %msg;
    while (@row = $sth->fetchrow_array ) {
        $msg{$row[0]}=$row[1];
    }
    return \%msg;
}

sub getWLANnetClientMessage
{
    my $clientid=shift;
    #print "SELECT StartTime,ticket FROM blacklist WHERE clientid = '$clientid' AND active = 1";
    my $sth = $main::dbh_ptc->prepare("SELECT StartTime,ticket FROM blacklist WHERE clientid = ? AND active=1;");
    $sth->execute($clientid);
    my @row;
    my %msg=();
    while (@row = $sth->fetchrow_array ) {
        #        print $row[0].$row[1];
        $msg{$row[0]}=$row[1];
    }
    #print time();
    return \%msg;
}

sub clearWLANnetMessage
{
        my $clientid=shift;
        if ($clientid)
        {
            $main::dbh_ptc->do("UPDATE blacklist SET StopTime = NOW(),active=0 WHERE clientid = ? AND active=1", undef, $clientid);
        }
        #$sth->execute();
        #    my @row;
        #my $msg="";
        #while ( @row = $sth->fetchrow_array ) {
        #$msg=$msg." ".$row[0]
        #}
        #return $msg;
}

sub updateWLANnetMessage
{
        my $clientid=shift;
        if ($clientid)
        {
            $main::dbh_ptc->do("UPDATE blacklist SET ReadTime = NOW() WHERE clientid = ? AND active=1", undef, $clientid);
        }
}

sub loadHPNAClient
{
    my $username=shift;
    $username=~s/\@wlanmail.com//;
    my %hpnaClients;
    my $sth = $main::dbh_hpna->prepare("SELECT Username,Attribute,Value FROM radreply WHERE UserName = ? ORDER BY Attribute;");
    $sth->execute($username);
    my @row;

    while ( @row = $sth->fetchrow_array ) {
        
        
        $hpnaClients{$row[0]}{$row[1]}=$row[2];
    }
    return \%hpnaClients;
}


sub addClient
{
    my ($username,$password,$clientid,$speed)=@_;
    
    if (!defined $speed)
    {
        $speed="1024/1024";
    }

    $main::dbh_hpna->do("INSERT INTO radcheck VALUES (NULL,?,'Cleartext-Password',':=',?)", undef, $username, $password);
    $main::dbh_hpna->do("INSERT INTO radreply VALUES (NULL,?,'Reply-Message',':=',?)", undef, $username, "$clientid/$username");
    $main::dbh_hpna->do("INSERT INTO radreply VALUES (NULL,?,'clientid',':=',?)", undef, $username, $clientid);
    $main::dbh_hpna->do("INSERT INTO radreply VALUES (NULL,?,'Filter-Id',':=',?)", undef, $username, $speed);
    my $error_str="Added";
    return \$error_str;

}






sub saveClientDevice
{
    my ($mac,$filterid,$replymessage)=@_;

    $mac=lc($mac);
    if ($mac !~m#(..\:..\:..\:..\:..\:..)#)
    {
        my $error_str="Invalid MAC address: $mac";
        return \$error_str;
    }

    if ($replymessage =~m#^(\d+)\/.*#)
    {
        my $clientid=$1;
        if (&checkRegister($mac))
        {
            my $error_str="MAC address already registered";
            $error_str=$main::dbh_hpna->do("UPDATE radreply set Value=? where  UserName=? and Attribute='Reply-Message'", undef, $replymessage, $mac);
            if ($error_str eq "0E0")
            {
                $main::dbh_hpna->do("INSERT INTO radreply VALUES (NULL,?,'Reply-Message',':=',?)", undef, $mac, $replymessage);
                $main::dbh_hpna->do("INSERT INTO radreply VALUES (NULL,?,'clientid',':=',?)", undef, $mac, $clientid);
            }
            elsif ($error_str eq 1)
            {
            }
            else
            {
                $error_str="!REPLY:".$error_str."!";
                return \$error_str;
            }


            if (defined $filterid)
            {
                $error_str=$main::dbh_hpna->do("UPDATE radreply SET Value=? where UserName=? and Attribute='Filter-Id'", undef, $filterid, $mac);
                if ($error_str eq "0E0")
                {
                    $main::dbh_hpna->do("INSERT INTO radreply VALUES (NULL,?,'Filter-Id',':=',?)", undef, $mac, $filterid);
                    return 1;
                }
                elsif ($error_str eq 1)
                {
                    return $error_str;
                }
                else
                {
                    $error_str="!FILTER:".$error_str."!";
                    return \$error_str;


                }
            }
            $error_str="OK $clientid";
            return \$error_str;
            return 0;

            return \$error_str;
        }
        else
        {

            $main::dbh_hpna->do("INSERT INTO radcheck VALUES (NULL,?,'Cleartext-Password',':=','getinfo')", undef, $mac);
            $main::dbh_hpna->do("INSERT INTO radreply VALUES (NULL,?,'Reply-Message',':=',?)", undef, $mac, $replymessage);
            $main::dbh_hpna->do("INSERT INTO radreply VALUES (NULL,?,'clientid',':=',?)", undef, $mac, $clientid);
            if (defined $filterid)
            {
                $main::dbh_hpna->do("INSERT INTO radreply VALUES (NULL,?,'Filter-Id',':=',?)", undef, $mac, $filterid);
                my $error_str="OK $clientid";
                return \$error_str;
                return 1;
            }
            my $error_str="OK $clientid";
            return \$error_str;
            return 0;
        }
    }
    else
    {
        my $error_str="Reply-Message not valid";
        return \$error_str;
    }
    my $error_str="OK";
    return \$error_str;
}




sub showHPNAAddress
{

    my $ref=loadHPNAClient($username);
    my %hpnaClients=%$ref;
    foreach (keys %hpnaClients)
    {
        my $ref=$hpnaClients{$_}{'Calling-Station-Id'};
        my %temphash=%$ref;
        foreach (keys %temphash)
        {
            Tvalue("Rekister�ity HPNA-MAC",$_);
        }
    }

}

sub checkRegister
{
    my $mac=shift;
    my $found=0;
    my $sth = $main::dbh_hpna->prepare("SELECT Username,Attribute,Value FROM radcheck WHERE UserName = ? and Attribute='clientid'  ORDER BY Attribute;");
    $sth->execute($mac);
    my @row;

    while ( @row = $sth->fetchrow_array ) {
        $found++;
    }
    

    return $found;
}


return 1;
