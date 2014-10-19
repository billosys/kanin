# Kanin / RabbitMQ Tutorials


## Overview

The Kanin Tutorials are several things:

1. In-depth documentation for Kanin, the LFE RabbitMQ client library;
1. An LFE port of the [Erlang RabbitMQ Tutorial code](https://github.com/rabbitmq/rabbitmq-tutorials/tree/master/erlang); and,
1. An LFE conversion of the [Python RabbitMQ tutorials](http://www.rabbitmq.com/tutorials/tutorial-one-python.html)


## Getting Set Up

Here's what you will need:

* A running RabbitMQ server - [instructions here](https://www.rabbitmq.com/download.html)
* The Kanin / RabbitMQ [starter project](https://github.com/billosys/kanin-tutorials-starter)

Followt the RabbitMQ download and installation instructions linked above.
Similarly, by following the instructions on the Kanin starter project Github
page, you will get the rest of the dependencies needed for these tutorials.

These tutorials assume that you have done the following:

```bash
$ git clone \
    https://github.com/billosys/kanin-tutorials-starter.git \
    kanin-tutorials
$ cd kanin-tutorials
$ make compile
```

All further instructions in the tutorials linked below are given from the
context of the ``kanin-tutorials`` directory.


## The Tutorials

Here are the LFE versions of the RabbitMQ Python tutorials:

1. [Hello World](./01-tutorial-hello-world.md)
1. [Work Queues](./02-tutorial-work-queues.md)
1. [Publish-Subscribe](./03-tutorial-pubsub.md)
1. [Routing](./04-tutorial-routing.md)
1. [Topics](./05-tutorial-topics.md)
