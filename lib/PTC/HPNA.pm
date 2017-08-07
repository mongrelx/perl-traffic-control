package PTC::HPNA;


require 5.000;
use Exporter;
use lib qw(/opt/perl-traffic-control/lib);
use PTC::Utils;
use Carp;

@ISA = qw(Exporter);

@EXPORT = qw(getPreviewMessage updateWLANnetMessage clearWLANnetMessage getWLANnetMessage getWLANnetClientMessage saveHPNAClient addHPNAClient showHPNAAddress  loadHPNAClient checkRegister getHPNAPassword saveHPNAPassword addClient updateClient addHPNAClientLANWORLD);






# Needs reason check
sub getWLANnetMessage
{
    my $username=shift;
    my $sth = $main::dbh_ptc->prepare("SELECT StartTime,ticket FROM blacklist WHERE UserName = '$username' AND StopTime = '0000-00-00 00:00:00' ;");
    $sth->execute();
    my @row;
    my $msg="";
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
    my $msg="";
    while (@row = $sth->fetchrow_array ) {
        $msg{$row[0]}=$row[1];
    }
    return \%msg;
}

sub getWLANnetClientMessage
{
    my $clientid=shift;
    #print "SELECT StartTime,ticket FROM blacklist WHERE clientid = '$clientid' AND active = 1";
    my $sth = $main::dbh_ptc->prepare("SELECT StartTime,ticket FROM blacklist WHERE clientid = '$clientid' AND active=1;");
    $sth->execute();
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
            my $sth = $main::dbh_ptc->do("UPDATE blacklist SET StopTime = NOW(),active=0 WHERE clientid = '$clientid' AND active=1 ;");
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
            my $sth = $main::dbh_ptc->do("UPDATE blacklist SET ReadTime = NOW() WHERE clientid = '$clientid' AND active=1 ;");
        }
}

sub loadHPNAClient
{
    my $username=shift;
    $username=~s/\@wlanmail.com//;
    my %hpnaClients;
    my $sth = $main::dbh_hpna->prepare("SELECT Username,Attribute,Value FROM radreply WHERE UserName = '$username' ORDER BY Attribute;");
    $sth->execute();
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

    $main::dbh_hpna->do("INSERT INTO radcheck VALUES (NULL,'$username','Cleartext-Password',':=','$password')");
    $main::dbh_hpna->do("INSERT INTO radreply VALUES (NULL,'$username','Reply-Message',':=','$clientid/$username')");
    $main::dbh_hpna->do("INSERT INTO radreply VALUES (NULL,'$username','clientid',':=','$clientid')");
    $main::dbh_hpna->do("INSERT INTO radreply VALUES (NULL,'$username','Filter-Id',':=','$speed')");
    my $error_str="Added";
    return \$error_str;

}

sub addHPNAClient
{
    my ($mac,$username,$password)=@_;
    $username=~s/\@wlanmail.com//;

    if ($mac !~m#(..\:..\:..\:..\:..\:..)#)
    {
        my $error_str="Laitteisto-osoite ei kelpaa : $mac";
        return \$error_str;
    }
    my $ref=loadHPNAClient($username);
    my %hpnaClients=%$ref;
    if (scalar keys %hpnaClients > 3)
    {
        my $error_str="Liikaa laitteisto-osoitteita / Too many MAC-Addresses ";
        return \$error_str;
    }
    foreach (keys %hpnaClients)
    {
        if ($hpnaClients{$_}{'clientid'} =~/\d+/)
        {
            $clientid=$hpnaClients{$_}{'clientid'};
            if (&checkRegister($mac))
            {
                my $error_str="Laitteisto-osoite on jo käytössä / MAC-Address is already registered";
                return \$error_str;
            }
            else
            {
                $main::dbh_hpna->do("INSERT INTO radcheck VALUES (NULL,'$mac','Cleartext-Password',':=','getinfo')");
                $main::dbh_hpna->do("INSERT INTO radreply VALUES (NULL,'$mac','Reply-Message',':=','$clientid/$username/$main::region')");
                $main::dbh_hpna->do("INSERT INTO radreply VALUES (NULL,'$mac','clientid',':=','$clientid')");

                if (exists $hpnaClients{$_}{'Filter-Id'})
                {
                    $main::dbh_hpna->do("INSERT INTO radreply VALUES (NULL,'$mac','Filter-Id',':=','$hpnaClients{$_}{'Filter-Id'}')");
                    return 1;
                }
                else
                {
                }
                return 0;
            }
        }
    }
}




sub saveHPNAClient
{
    my ($mac,$filterid,$replymessage)=@_;

    $mac=lc($mac);
    if ($mac !~m#(..\:..\:..\:..\:..\:..)#)
    {
        my $error_str="Laitteisto-osoite ei kelpaa : $mac";
        return \$error_str;
    }

    if ($replymessage =~m#^(\d+)\/.*#)
    {
        $clientid=$1;;
        if (&checkRegister($mac))
        {
            my $error_str="Laitteisto-osoite on jo käytössä / MAC-Address is already registered";
            $error_str=$main::dbh_hpna->do("UPDATE radreply set Value='$replymessage' where  UserName='$mac' and Attribute='Reply-Message'");
            if ($error_str eq "0E0")
            {
                $main::dbh_hpna->do("INSERT INTO radreply VALUES (NULL,'$mac','Reply-Message',':=','$replymessage')");
                $main::dbh_hpna->do("INSERT INTO radreply VALUES (NULL,'$mac','clientid',':=','$clientid')");
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
                $error_str=$main::dbh_hpna->do("UPDATE radreply SET Value='$filterid' where UserName='$mac' and Attribute='Filter-Id'");
                if ($error_str eq "0E0")
                {
                    $main::dbh_hpna->do("INSERT INTO radreply VALUES (NULL,'$mac','Filter-Id',':=','$filterid')");
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
            
            $main::dbh_hpna->do("INSERT INTO radcheck VALUES (NULL,'$mac','Cleartext-Password',':=','getinfo')");
            $main::dbh_hpna->do("INSERT INTO radreply VALUES (NULL,'$mac','Reply-Message',':=','$replymessage')");
            $main::dbh_hpna->do("INSERT INTO radreply VALUES (NULL,'$mac','clientid',':=','$clientid')");            
            if (defined $filterid)
            {
                $main::dbh_hpna->do("INSERT INTO radreply VALUES (NULL,'$mac','Filter-Id',':=','$filterid')");
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
            Tvalue("Rekisteröity HPNA-MAC",$_);
        }
    }

}

sub checkRegister
{
    my $mac=shift;
    my $found=0;
    my $sth = $main::dbh_hpna->prepare("SELECT Username,Attribute,Value FROM radcheck WHERE UserName = '$mac' and Attribute='clientid'  ORDER BY Attribute;");
    $sth->execute();
    my @row;

    while ( @row = $sth->fetchrow_array ) {
        $found++;
    }
    

    return $found;
}


return 1;
