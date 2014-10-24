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

## Documentation

Below, in the "Usage" section, you will find information about using Kanin
with RabbitMQ in LFE projects.

Also, you may be interested in the [Kanin tutorials](./doc/tutorials.md), which
have been translated from the official RabbitMQ docs for Python and Erlang.



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

The general mechanism of interacting with the broker is to send and receive AMQP
commands that are defined in the protocol documentation. During build process,
the machine-readable version of the AMQP specification is used to auto-generate
Erlang records for each command. The code generation process also defines
sensible default values for each command. Using default values allows the
programmer to write terser code - it is only necessary to override a field if
you require non-default behaviour. The definition of each command can be
consulted in the ``include/rabbit-framing.lfe`` header file. For example,
when using the ``(make-exchange.declare ...)`` record-creating macro,
specifying the following:

```cl
(make-exchange.declare exchange (list_to_binary "my_exchange"))
```

is equivalent to this:

```cl
(make-exchange.declare
  exchange (list_to_binary "my_exchange")
  ticket 0
  type (list_to_binary "direct")
  passive 'false
  durable 'false
  auto_delete 'false
  internal 'false
  nowait 'false
  arguments '())
```

### Including Header Files

The LFE client uses a number of record definitions which you will encounter
in this guide. These records fall into two broad categories:

* Auto-generated AMQP command definitions from the machine readable version of
  the specification
* Definitions of data structures that are commonly used throughout the client

To gain access to these records, you need to include the ``amqp-client.lfe``
file in every module that uses the Erlang client:

```cl
(include-lib "kanin/include/amqp-client.lfe")
```


### Connecting to a Broker

The ``kanin-conn`` module is used to start a connection to the broker:

```cl
...
    (let* ((net-opts (make-amqp_params_network host "localhost"))
         (`#(ok ,connection) (kanin-conn:start net-opts))
         ...))
...
```

This function returns ``#(ok ,connection)``, where ``connection`` is the pid of a
process that maintains a permanent connection to the broker.

In case of an error, the above call returns ``#(error ,error)``.

The example above has just ``"localhost"`` as a parameter. However, there will
often be many more than that.

An AMQP broker contains objects organised into groups called virtual hosts. The
concept of virtual hosts gives an administrator the facility to partition a
broker resource into separate domains and restrict access to the objects
contained within these groups. AMQP connections require client authentication
and the authorisation to access specific virtual hosts.

The ``(make-amqp_params_network)`` record macro sets the following default
values:

| Parameter         |  Default Value  |
|-------------------|-----------------|
| username          |  guest          |
| password          |  guest          |
| virtual_host      |  /              |
| host              |  localhost      |
| post              |  5672           |
| channel_max       |  0              |
| frame_max         |  0              |
| heartbeat         |  0              |
| ssl_options       |  none           |
| auth_mechanisms   |  ``(list #'amqp_auth_mechanisms:plain/3 #'amqp_auth_mechanisms:amqplain/3)`` |
| client_properties |  ``'()``        |

These values are only the defaults that will work with an out of the box broker
running on the same host. If the broker or the environment has been configured
differently, these values can be overridden to match the actual deployment
scenario.

SSL options can also be specified globally using the ``ssl_options`` environment
key for the ``amqp-client`` application. They will be merged with the SSL
parameters from the URI (the latter will take precedence).

If a client wishes to run inside the same Erlang cluster as the RabbitMQ broker,
it can start a direct connection that optimises away the AMQP codec. To start a
direct connection, use ``kanin-conn:start/1`` with the parameter set to an
``(make-amqp_params_direct)`` record.

Providing a username and password is optional, since the direct client is
considered trusted anyway. If a username and password are provided then they
will be checked and made available to authentication backends. If a username is
supplied, but no password, then the user is considered trusted and logged in
unconditionally. If neither username nor password are provided then the
connection will be considered to be from a "dummy" user which can connect to any
virtual host and issue any AMQP command.

The ``(make-amqp_params_direct)`` record macro sets the following default
values:

| Parameter         |  Default Value  |
|-------------------|-----------------|
| username          |  guest          |
| password          |  guest          |
| virtual_host      |  /              |
| node              |  ``(node)``     |
| client_properties |  ``'()``        |


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

