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

Add content to me here!
