package Rex::Endpoint::HTTP::Fs;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON;
use Mojo::Upload;
use Data::Dumper;
use Cwd;

# This action will render a template
sub ls {
   my $self = shift;

   my @ret;
   opendir(my $dh, $self->_path) or return $self->render({ok => Mojo::JSON->false});
   while(my $entry = readdir($dh)) {
      next if($entry eq "." || $entry eq "..");
      push(@ret, $entry);
   }
   closedir($dh);

   $self->render_json({ok => Mojo::JSON->true, ls => \@ret});
}

sub is_dir {
   my $self = shift;

   if(-d $self->_path) {
      $self->render_json({ok => Mojo::JSON->true});
   }
   else {
      $self->render_json({ok => Mojo::JSON->false});
   }
}

sub is_file {
   my $self = shift;

   if(-f $self->_path) {
      $self->render_json({ok => Mojo::JSON->true});
   }
   else {
      $self->render_json({ok => Mojo::JSON->false});
   }
}

sub unlink {
   my $self = shift;

   CORE::unlink($self->_path) or 
            return $self->render_json({ok => Mojo::JSON->false});
            
   $self->render_json({ok => Mojo::JSON->true});
}

sub mkdir {
   my $self = shift;
   
   CORE::mkdir($self->_path) or
            return $self->render_json({ok => Mojo::JSON->false});

   $self->render_json({ok => Mojo::JSON->true});
}

sub stat {
   my $self = shift;

   my %stat = CORE::stat($self->_path);

   $self->render_json({ok => Mojo::JSON->true, stat => \%stat});
}

sub is_readable {
   my $self = shift;

   if(-r $self->_path) {
      $self->render_json({ok => Mojo::JSON->true});
   }

   $self->render_json({ok => Mojo::JSON->false});
}

sub is_writable {
   my $self = shift;

   if(-w $self->_path) {
      $self->render_json({ok => Mojo::JSON->true, is_writable => Mojo::JSON->true});
   }
}

sub readlink {
   my $self = shift;

   my $link = CORE::readlink($self->_path);

   $self->render_json({ok => Mojo::JSON->true, link => $link});
}

sub rename {
   my $self = shift;

   my $ref = $self->req->json;
   my $old = $ref->{old};
   my $new = $ref->{new};

   CORE::rename($old, $new) or
      return $self->render_json({ok => Mojo::JSON->false});

   $self->render_json({ok => Mojo::JSON->true});
}

sub glob {
   my $self = shift;

   my @glob = CORE::glob($self->req->json->{"glob"});

   $self->render_json({ok => Mojo::JSON->true, glob => \@glob});
}

sub upload {
   my $self = shift;

   my $path = $self->req->param("path");
   my $upload = $self->req->upload("content");

   open(my $fh, ">", $path) or return $self->render_json({ok => Mojo::JSON->false});
   print $fh $upload->slurp;
   close($fh);

   $self->render_json({ok => Mojo::JSON->true});
}

sub download {
   my $self = shift;

   # is there a better way to serve static files?
   my $path = getcwd();
   $path =~ s/[^\/]+/../g;

   if(! -f "../$path" . $self->_path) {
      return $self->render_json({ok => Mojo::JSON->false}, status => 404);
   }

   $self->render_static("../" . $path . $self->_path);
}

sub _path {
   my $self = shift;
   
   my $ref = $self->req->json;
   return $ref->{path};
}

1;
