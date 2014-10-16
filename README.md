# kanin

<a href="http://aquarius-galuxy.deviantart.com/art/Rabbit-Drawing-176749973"><img src="resources/images/kanin-small.png" /></a>

*An LFE Wrapper for the Erlang RabbitMQ (AMQP) Client*


## Introduction

Add content to me here!


## Installation

Just add it to your ``rebar.config`` deps:

```erlang
  {deps, [
    ...
    {kanin, ".*",
      {git, "git@github.com:billosys/kanin.git", "master"}}
      ]}.
```

And then do:

```bash
    $ make compile
```

This will take a little while, as it builds the Erlang RabbitMQ client library
from source. If you have ``amqp_lib`` on your ``$ERL_LIBS`` path, then you can
do this instead:

```bash
	$ make skip-rabbit
```

## Usage

### Copyright Notice

The following content was copied from
[the Erlang Client User Guide](https://www.rabbitmq.com/erlang-client-user-guide.html)
on the [RabbitMQ site](https://www.rabbitmq.com/).
The original copyright was in 2014, held by Pivotal Software, Inc.

### The LFE AMQP Client Library

The AMQP client provides an Erlang interface to compliant AMQP brokers. The
client follows the AMQP execution model and implements the wire level
marshaling required to encode and decode AMQP commands in a protocol
conformant fashion. AMQP is a connection orientated protocol and multiplexes
parallel interactions via multiple channels within a connection.

This user guide assumes that the reader is familiar with basic concepts of AMQP
and understands exchanges, queues and bindings. This information is contained in
the protocol documentation on the AMQP website. For details and exact
definitions, please see
[the AMQP specification document](http://www.amqp.org/).

The basic usage of the client follows these broad steps:

 * Establish a connection to a broker
 * Create a new channel within the open connection
 * Execute AMQP commands with a channel such as sending and receiving messages,
   creating exchanges and queue or defining routing rules between exchanges and
   queues
 * When no longer required, close the channel and the connection


### Programming Model

The two currently supported modules in the kanin library are:

 * ``kanin-conn`` (wraps ``amqp_connection``) - used to open connections to a
   broker and create channels.
 * ``kanin-chan`` (wraps ``amqp_channel``) - used to send and receive AMQP
   commands.

Once a connection has been established, and a channel has been opened, an
LFE application will typically use the ``kanin-chan:call/{2,3}`` and
``kanin-chan:cast/{2,3}`` functions to achieve most of the things it needs to
do.

The underlying Erlang AMQP client library is made up of two layers:

 * A high level logical layer that follows the AMQP execution model, and
 * A low level driver layer that is responsible for providing a physical
   transport to a broker.

There are two drivers in the client library:

 * The network driver establishes a TCP connection to a protocol compliant AMQP
   broker and encodes each command according to the specification. To use this
   driver, start a connection using ``kanin-conn:start/1`` with the parameter
   set to an ``#amqp_params_network`` record.

 * The direct driver uses native Erlang messaging instead of sending AMQP
   encoded commands over TCP. This approach avoids the overhead of marshaling
   commands onto and off the wire. However, the direct driver can only be used
   in conjunction with the RabbitMQ broker and the client code must be deployed
   into the same Erlang cluster. To use the direct driver, start a connection
   using ``kanin-conn:start/1`` with the parameter set to an
   ``#amqp_params_direct`` record.

At run-time, the Erlang client library re-uses a subset of the functionality
from the RabbitMQ broker. In order to keep the a client deployment independent
of RabbitMQ, the Erlang client build process produces an archive containing all
of the common modules. This archive is then put onto the load path of the client
application.

For more detailed information on the API, please refer to the reference
documentation.

Furthermore, the test suite that is part of the source distribution of the
client library contains many complete examples of how to program against the
API.

### AMQP Commands

TBD

### Including Header Files

TBD

### Connecting to a Broker

TBD

### Connecting To A Broker with AMQP URIs

TBD

### Creating Channels

TBD

### Managing Exchanges and Queues

TBD

### Sending Messages

TBD

### Receiving Messages

TBD

### Subscribing to Queues

TBD

### Subscribing Internals

TBD

### Closing Channels and the Connection

TBD

### Complete Example

TBD

### Client Deployment

TBD

### Egress Flow Control

TBD

### Ingress Flow Control

TBD

### Handling Returned Messages

TBD

