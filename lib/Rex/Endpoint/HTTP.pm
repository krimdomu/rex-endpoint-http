package Rex::Endpoint::HTTP;
use Mojo::Base 'Mojolicious';

our $VERSION = "0.0.1";

# This method will run once at server start
sub startup {
   my $self = shift;

   # Documentation browser under "/perldoc"
   #$self->plugin('PODRenderer');

   # Router
   my $r = $self->routes;

   # Normal route to controller
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
}

1;
