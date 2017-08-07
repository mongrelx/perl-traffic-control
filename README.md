# perl-traffic-control

<h2>Perl QoS and traffic shaping.</h2>
<ul>
<li>RRD logging & graphing
<li>Webmin module
<li>Curses interface
<li>Captive portal
<li>Scales up to 2000 user, but easy to shape traffic on small scale too
<li>I'm currently using it to ensure my bandwidth in family shared lined as kids consume lot's of bandwidth
<li>Either per device or per user bw
<li>blacklist 
<li>timed events
</ul>

This was in production usage between 2000-2012 and it performed quite nicely

<h2>Requirements</h2>
<ul>
<li> linux kernel with htc support
<li> mysql > 4.0.0
<li> http-server
<li> iptables
<li> perl > 5.0
<li> Curses::Application
<li> DBI
<li> DBH::mysql
</ul>

<h2>Optional</h2>
<ul>
<li> radius
<li> Authen::Radius
<li> iptraf
</ul>

<h2>Installation on debian</h2>
<ul>
<li> apt-get install git
<br>
<li> apt-get install libdbi-perl librrdtool-oo-perl 
<li> apt-get install libdbd-mysql libdbd-mysql-perl libmysqlclient18
<li> apt-get install libconvert-ber-perl mysql-server freeradius-mysql libauthen-radius-perl
<li> apt-get install libcurses-perl libjson-perl libsnmp-perl libsnmp-session-perl libexporter-autoclean-perl
<li> cpan -i Curses::Application
<!---<li> cpan -i RRD ???-->
<li> cd /opt/
<li> git clone https://github.com/mongrelx/perl-traffic-control.git
</ul>

<h2>Configuration</h2>
<h3>Database</h3>
<ul>
<li> mysqladmin create ptc -p
<li> mysqladmin create ptc_auth -p
<li> mysql -p<br>
mysql>GRANT ALL PRIVILEGES   ON ptc.* TO 'ptc_user'@'%'   IDENTIFIED BY 'ptc_pass';
mysql>GRANT ALL PRIVILEGES   ON ptc_auth.* TO 'ptc_user'@'%'   IDENTIFIED BY 'ptc_pass';        
<li> (DEBIAN 8) mysql -p ptc_auth < /etc/freeradius/sql/mysql/schema.sql
<li> (DEBIAN 9)  mysql -p ptc_auth < /etc/freeradius/3.0/mods-config/sql/main/mysql/schema.sql
</ul>
<h3>Web-server</h3>
<h3>Interfaces</h3>
<h3>Radius</h3>
<ul>
        
<h4>debian 8</h4>
<li> edit sql.conf to match db_user,db_pass,db_name
<li> include sql.conf from freeradius.conf
<li> add to /etc/freeradius/users <br>
DEFAULT Autz-Type :=PTC_USER <br>
        Fall-Through = Yes<br>
<li> add to /etc/freeradius/sites-enable/default<br>
under Authorization section<br>

 Autz-Type PTC_USER {
                sql
        }
</ul>

<ul>
        
<h4>debian 9</h4>
<li> edit /etc/freeradius/mods-available/sql to match db_user,db_pass,db_name
<li> enable mod sql
<li> add to /etc/freeradius/3.0/users <br>
DEFAULT Autz-Type :=PTC_USER <br>
        Fall-Through = Yes<br>
<li> add to /etc/freeradius/sites-enabled/default<br>
under Authorization section<br>

 Autz-Type PTC_USER {
                sql
        }
</ul>

edit /opt/perl-traffic-control/etc/AAA/home.AAA.conf to match your network


/opt/perl-traffic-control/bin/iptable-basic  > /etc/iptables.up.rules 
iptables-restore < /etc/iptables.up.rules



<h2>Usage</h2>

