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

The following content was copied from the Erlang Client User Guide on the
RabbitMQ site. The original copyright was in 2014, held by Pivotal Software,
Inc.

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

TBD

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

