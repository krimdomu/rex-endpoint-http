#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
=head1 NAME

Rex::Endpoint::HTTP - Execute Rex over HTTP

=head1 DESCRIPTION

This is a replacement for the default SSH endpoint of Rex.

=head1 DEPENDENCIES

=over 4

=item * Mojolicious

=item * Digest::SHA

=back

=head1 CONFIGURATION

=head2 Configuration File

rex_endpoint_http search at multiple locations for the configuration file. In this file you can define a user database file and configure the build in webserver (hypnotoad from Mojolicious).

=over 4

=item * /etc/rex/httpd.conf

=item * /usr/local/etc/rex/httpd.conf

=item * ./httpd.conf

=back

The format of the file is a Perl Hash Reference. So you have to start and end the file with braces. 

 {
    key1 => "value1",
    key2 => "value2",
 };

=head2 Configure Hypnotoad

As a default hypnotoad listens on every device on port 8080 without encryption. This is a thing you want to change on production servers. To configure hypnotoad you have to add a new section. It is possible to use it without encryption but we advise you not to do that. If you have your own CA or want to create one, please read I<SSL Authentication>.

 hypnotoad => {
    listen => ['https://127.0.0.1:8433'],
 },

The full file may look like this:

 {
    hypnotoad => {
       listen => ['https://127.0.0.1:8443'],
    },
 };

=head2 User/Password Authentication

If you want to use basic user/password authentication you have to add the location of the user file into the configuration. The key is I<user_file>.

 user_file => "/path/to/your/user.db",

The full file may look like this:

 {
    user_file => "/path/to/your/user.db",
       
    # configure hypnotoad
    hypnotoad => {
       listen => ['https://127.0.0.1:8443'],
    },
 };

You also have to create a user database for the authentication.

This file exists of 2 columns seperated by ":". 

 username:sha1crypted-password

You can create the sha1 strings with the following command.

 perl -MDigest::SHA -le 'print Digest::SHA::sha1_hex("your-password")'


=head2 SSL Authentication

If you want to use SSL Authentication (with client/server certificates) you have to configure it. Open the file I</etc/rex/httpd.conf> and modify the I<listen> line. And now you can remove the I<user_file> line.

 {
    hypnotoad => {
       listen => ["https://*:8443?cert=/path/to/your/cert-file.crt&key=/path/to/your/private.key&ca=/path/to/your/ca-file.crt"],
    },
 };

It is also possible to put Apache or another Webserver in front of it. This is an example configuration:

 <VirtualHost _default_:8443>
    ServerName your-server.your-domain.tld
    ServerAlias your-server
    
    SSLEngine on
    
    SSLCertificateFile    /etc/apache2/ssl/ssl.crt
    SSLCertificateKeyFile /etc/apache2/ssl/ssl.key
    SSLCACertificateFile  /etc/apache2/ssl/ca.crt
    
    SSLVerifyClient require
    SSLVerifyDepth  10
    SSLOptions +FakeBasicAuth +ExportCertData +StrictRequire
    
    <Location />
       ProxyPass http://localhost:8080/
       ProxyPassReverse http://localhost:8080/
   </Location>
   
 </VirtualHost>

For this to work you need to create your own Certificate Authority (CA). There is a Rex recipe that will help you. Just create a small Rex project.

 bash# rexify ca --use Rex::SSL::CA
 bash# cd ca
 bash ~/ca# cat >Rexfile<<EOF
 require Rex::SSL::CA;
 require Rex::SSL::CA::Server;
 EOF

Please don't use a servername for the I<cn> parameter here!

 bash# rex SSL:CA:create --password=pass [--country=cn --state=state --city=city --org=organization --unit=organizational-unit --cn=name-of-the-ca --email=email]


And to create a server/client certificate you can use the following task. Here you have to use the server name for the I<cn> parameter.

 bash# rex SSL:CA:Server:create --cn=name-of-the-server --password=password [--challenge-password=challenge-password --country=country --state=state --city=city --org=organization --unit=organizational-unit --email=email]

After that you can copy the cert file from ca/certs/$cn.crt and the keyfile from ca/private/$cn.key. The CA Cert file is located at ca/certs/ca.crt.

=head1 USAGE

To use the HTTP/S endpoint in your rexfiles you just have to enable it.

To use HTTP Transport use the following line inside your Rexfile:

 set connection => "http";

To use HTTPS Transport use this one:

 set connection => "https";

If you want to use HTTPS/SSL Authentication use this:

 set connection => "https";
 set ca => "/path/to/ca-cert-file.crt";
 set cert => "/path/to/client-cert-file.crt";
 set key => "/path/to/client-key-file.key"; 


=head1 INIT

You can download an init script from I<https://github.com/krimdomu/rex-endpoint-http/tree/master/doc>.

=cut


package Rex::Endpoint::HTTP;
use Mojo::Base 'Mojolicious';

our $VERSION = "0.35.0";

BEGIN {
    $ENV{MOJO_MAX_MESSAGE_SIZE} = 2 * 1024 * 1024 * 1024; # 2 GB
};

use Rex::Endpoint::HTTP::Interface::System;

# This method will run once at server start
sub startup {
   my $self = shift;

   my @cfg = ("/etc/rex/httpd.conf", "/usr/local/etc/rex/httpd.conf", "httpd.conf");
   my $cfg = "httpd.conf";
   for my $file (@cfg) {
      if(-f $file) {
         $cfg = $file;
         last;
      }
   }

   if(-f $cfg) {
      # load config if available
      $self->plugin('Config', file => $cfg);

      # do authentication, if needed
      if(exists $self->{defaults}->{config} && exists $self->{defaults}->{config}->{user_file}) {
         $self->plugin("Rex::Endpoint::HTTP::Mojolicious::Plugin::Auth");
      }
   }

   # Router
   my $r = $self->routes;

   # Normal route to controller
   $r->get("/")->to("base#index");

   $r->post("/login")->to("login#index");
   $r->post("/execute")->to("execute#index");

   $r->post("/fs/ls")->to("fs#ls");
   $r->post("/fs/is_dir")->to("fs#is_dir");
   $r->post("/fs/is_file")->to("fs#is_file");

   $r->post("/fs/unlink")->to("fs#unlink");
   $r->post("/fs/mkdir")->to("fs#mkdir");

   $r->post("/fs/stat")->to("fs#stat");

   $r->post("/fs/is_readable")->to("fs#is_readable");
   $r->post("/fs/is_writable")->to("fs#is_writable");

   $r->post("/fs/readlink")->to("fs#readlink");
   $r->post("/fs/rename")->to("fs#rename");

   $r->post("/fs/glob")->to("fs#glob");

   $r->post("/fs/upload")->to("fs#upload");
   $r->post("/fs/download")->to("fs#download");

   $r->post("/fs/rmdir")->to("fs#rmdir");
   $r->post("/fs/ln")->to("fs#ln");

   $r->post("/fs/chown")->to("fs#chown");
   $r->post("/fs/chgrp")->to("fs#chgrp");
   $r->post("/fs/chmod")->to("fs#chmod");

   $r->post("/fs/cp")->to("fs#cp");

   $r->post("/file/open")->to("file#open");
   $r->post("/file/close")->to("file#close");
   $r->post("/file/read")->to("file#read");

   # this seems odd, but "write" is not allowed as an action
   $r->post("/file/write_fh")->to("file#write_fh");

   $r->post("/file/seek")->to("file#seek");

   # load system specific routes
   my $sys = Rex::Endpoint::HTTP::Interface::System->create;
   $sys->set_routes($r);
}

1;
