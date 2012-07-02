package Rex::Endpoint::HTTP::File;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON;
use MIME::Base64;

sub open {
   my $self = shift;

   my $ref = $self->req->json;

   CORE::open(my $fh, $ref->{mode}, $self->_path) or return $self->render_json({ok => Mojo::JSON->false});
   CORE::close($fh);

   $self->render_json({ok => Mojo::JSON->true});
}

sub read {
   my $self = shift;

   my $ref = $self->req->json;
   
   my $file = $self->_path;
   my $start = $ref->{start};
   my $len = $ref->{len};

   CORE::open(my $fh, "<", $file) or return $self->render_json({ok => Mojo::JSON->false});
   CORE::seek($fh, $start, 0);
   my $buf;
   sysread($fh, $buf, $len);
   CORE::close($fh);

   $self->render_json({ok => Mojo::JSON->true, buf => encode_base64($buf)});
}

# this seems odd, but "write" is not allowed as an action
sub write_fh {
   my $self = shift;

   my $ref = $self->req->json;

   my $file = $self->_path;
   my $start = $ref->{start};
   my $buf = decode_base64($ref->{buf});

   CORE::open(my $fh, "+<", $file) or return $self->render_json({ok => Mojo::JSON->false});
   CORE::seek($fh, $start, 0);
   print $fh $buf;
   CORE::close($fh);

   $self->render_json({ok => Mojo::JSON->true});
}

sub seek {
   my $self = shift;
   $self->render_json({ok => Mojo::JSON->true});
}

sub close {
   my $self = shift;
   $self->render_json({ok => Mojo::JSON->true});
}

sub _path {
   my $self = shift;
   
   my $ref = $self->req->json;
   return $ref->{path};
}

1;
