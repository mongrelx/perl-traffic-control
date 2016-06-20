# perl-traffic-control

Perl QoS and traffic shaping.
RRD logging & graphing
Webmin module
Curses interface
Captive portal


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

<h2>Installation debian</h2>
<ul>
<li> apt-get install libdbi-perl 
<li> apt-get install libdbd-mysql libdbd-mysql-perl libmysqlclient18
<li> apt-get install libconvert-ber-perl
<li> apt-get install libsnmp-perl libsnmp-session-perl libexporter-autoclean-perl
<li> perl -MCPAN -e 'install Curses::Application'
<li> cd /opt/
<li> git clone https://github.com/mongrelx/perl-traffic-control.git
</ul>

<h2>Configuration</h2>
<h3>Database<h3>
<h3>Web-server<h3>
<h3>Interfaces<h3>
<h3>Radius<h3>
<h2>Usage</h2>

