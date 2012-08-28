#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Endpoint::HTTP::Interface::File::Base;
   
use strict;
use warnings;

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = { @_ };

   bless($self, $proto);

   return $self;
}

sub ls {
   my ($self, $path) = @_;

   my @ret;
   opendir(my $dh, $path) or die($!);
   while(my $entry = readdir($dh)) {
      next if($entry eq "." || $entry eq "..");
      push(@ret, $entry);
   }
   closedir($dh);

   return @ret;
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

   if(my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size,
               $atime, $mtime, $ctime, $blksize, $blocks) = CORE::stat($self->_path)) {

         my %ret;

         $ret{'mode'}  = sprintf("%04o", $mode & 07777); 
         $ret{'size'}  = $size;
         $ret{'uid'}   = $uid;
         $ret{'gid'}   = $gid;
         $ret{'atime'} = $atime;
         $ret{'mtime'} = $mtime;

         return $self->render_json({ok => Mojo::JSON->true, stat => \%ret});
   }

   $self->render_json({ok => Mojo::JSON->false}, status => 404);
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

   if(! -f $self->_path) {
      return $self->render_json({ok => Mojo::JSON->false}, status => 404);
   }

   my $content = eval { local(@ARGV, $/) = ($self->_path); <>; };

   $self->render_json({
      ok => Mojo::JSON->true,
      content => encode_base64($content),
   });
}

sub ln {
   my $self = shift;

   my $ref = $self->req->json;

   if(-f $ref->{to}) {
      CORE::unlink($ref->{to});
   }

   CORE::symlink($ref->{from}, $ref->{to}) and
      return $self->render_json({ok => Mojo::JSON->true});

   $self->render_json({ok => Mojo::JSON->false});
}

sub rmdir {
   my $self = shift;

   system("rm -rf " . $self->_path);

   if($? == 0) {
      return $self->render_json({ok => Mojo::JSON->true});
   }

   $self->render_json({ok => Mojo::JSON->false});
}

sub chown {
   my $self = shift;

   my $ref = $self->req->json;

   my $user = $ref->{user};
   my $file = $self->_path;
   my $options = $ref->{options};

   my $recursive = "";
   if(exists $options->{"recursive"} && $options->{"recursive"} == 1) {
      $recursive = " -R ";
   }

   system("chown $recursive $user $file");

   if($? == 0) {
      return $self->render_json({ok => Mojo::JSON->true});
   }

   $self->render_json({ok => Mojo::JSON->false});
}

sub chgrp {
   my $self = shift;

   my $ref = $self->req->json;
   my $group = $ref->{group};
   my $file = $self->_path;

   my $options = $ref->{options};

   my $recursive = "";
   if(exists $options->{"recursive"} && $options->{"recursive"} == 1) {
      $recursive = " -R ";
   }

   system("chgrp $recursive $group $file");

   if($? == 0) {
      return $self->render_json({ok => Mojo::JSON->true});
   }

   $self->render_json({ok => Mojo::JSON->false});
}

sub chmod {
   my $self = shift;

   my $ref = $self->req->json;
   my $mode = $ref->{mode};
   my $file = $self->_path;
   my $options = $ref->{options};

   my $recursive = "";
   if(exists $options->{"recursive"} && $options->{"recursive"} == 1) {
      $recursive = " -R ";
   }

   system("chmod $recursive $mode $file");

   if($? == 0) {
      return $self->render_json({ok => Mojo::JSON->true});
   }

   $self->render_json({ok => Mojo::JSON->false});
}

sub cp {
   my $self = shift;

   my $ref = $self->req->json;

   my $source = $ref->{source};
   my $dest   = $ref->{dest};

   system("cp -R $source $dest");

   if($? == 0) {
      return $self->render_json({ok => Mojo::JSON->true});
   }

   $self->render_json({ok => Mojo::JSON->false});
}

1;
