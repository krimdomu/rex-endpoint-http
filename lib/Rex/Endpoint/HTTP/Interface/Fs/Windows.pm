#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Endpoint::HTTP::Interface::Fs::Windows;
   
use strict;
use warnings;

use Rex::Endpoint::HTTP::Interface::Fs::Base;
use base qw(Rex::Endpoint::HTTP::Interface::Fs::Base);

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = $proto->SUPER::new(@_);

   bless($self, $proto);

   return $self;
}

1;
