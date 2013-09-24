use 5.008001;
use strict;
use warnings;

package Dancer::Plugin::Queue::MongoDB;
# ABSTRACT: Dancer::Plugin::Queue backend using MongoDB
# VERSION

# Dependencies
use Moose;
use MooseX::AttributeShortcuts;
use MongoDBx::Queue 1.000; # new API
use namespace::autoclean;

with 'Dancer::Plugin::Queue::Role::Queue';

=attr db_name

Name of the database to hold the queue collection. Required.

=cut

has db_name => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

=attr queue_name

Name of the collection that defines the queue. Defaults to 'queue'.

=cut

has queue_name => (
  is      => 'ro',
  isa     => 'Str',
  default => 'queue',
);

=attr connection_options

MongoDB::Connection options hash to create the connection to the database
holding the queue.  Empty by default, which means connecting to localhost
on the default port.

=cut

has connection_options => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);

=attr queue

The MongoDBX::Queue object that manages the queue.  Built on demand from
other attributes.

=cut

has queue => (
  is         => 'lazy',
  isa        => 'MongoDBx::Queue',
);

sub _build_queue {
  my ($self) = @_;
  return MongoDBx::Queue->new(
    database_name => $self->db_name,
    collection_name => $self->queue_name,
    client_options => $self->connection_options,
  );
}

sub add_msg {
  my ( $self, $data ) = @_;
  $self->queue->add_task( { data => $data } );
}

sub get_msg {
  my ($self) = @_;
  my $msg = $self->queue->reserve_task;
  return ( $msg, $msg->{data} );
}

sub remove_msg {
  my ( $self, $msg ) = @_;
  $self->queue->remove_task($msg);
}

__PACKAGE__->meta->make_immutable;

1;

=for Pod::Coverage add_msg get_msg remove_msg

=head1 SYNOPSIS

  # in config.yml

  plugins:
    Queue:
      default:
        class: MongoDB
        options:
          db_name: dancer_test
          queue_name: msg_queue
          connection_options:
            host: mongodb://localhost:27017

  # in Dancer app

  use Dancer::Plugin::Queue::MongoDB;

  get '/' => sub {
    queue->add_msg( $data );
  };

=head1 DESCRIPTION

This module implements a L<Dancer::Plugin::Queue> using L<MongoDBx::Queue>.

=head1 USAGE

See documentation for L<Dancer::Plugin::Queue>.

=head1 SEE ALSO

=for :list
* L<Dancer::Plugin::Queue>
* L<MongoDBx::Queue>
* L<MongoDB::Connection>

=cut

# vim: ts=2 sts=2 sw=2 et:
