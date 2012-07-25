package Rex::Endpoint::HTTP;
use Mojo::Base 'Mojolicious';

our $VERSION = "0.0.8";

BEGIN {
    $ENV{MOJO_MAX_MESSAGE_SIZE} = 2 * 1024 * 1024 * 1024; # 2 GB
};

# This method will run once at server start
sub startup {
   my $self = shift;

   my @cfg = ("/etc/rex/httpd.conf", "/usr/local/etc/rex/httpd.conf", "httpd.conf");
   my $cfg;
   for my $file (@cfg) {
      if(-f $file) {
         $cfg = $file;
         last;
      }
   }
   $self->plugin('Config', file => $cfg);

   # do authentication
   $self->plugin("Rex::Endpoint::HTTP::Mojolicious::Plugin::Auth");

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
}

1;
