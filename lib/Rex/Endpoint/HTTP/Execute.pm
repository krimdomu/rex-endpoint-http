package Rex::Endpoint::HTTP::Execute;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON;

# This action will render a template
sub index {
   my $self = shift;

   my $ref = $self->req->json;
   my $cmd = $ref->{exec};

   my $out = qx{$cmd};

   $self->render_json({ok => Mojo::JSON->true, output => $out});
}

1;
