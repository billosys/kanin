# Kanin / RabbitMQ Tutorials

## Hello World


### Introduction

RabbitMQ is a message broker. The principal idea is pretty simple: it accepts
and forwards messages. You can think about it as a post office: when you send
mail to the post box you're pretty sure that Mr. Postman will eventually deliver
the mail to your recipient. Using this metaphor RabbitMQ is a post box, a post
office and a postman.

The major difference between RabbitMQ and the post office is the fact that it
doesn't deal with paper, instead it accepts, stores and forwards binary blobs of
data ‒ messages.

RabbitMQ, and messaging in general, uses some jargon.

* **Producer** - Producing means nothing more than sending. A program   that
  sends messages is a producer.

* **Queue** - A queue is the name for a mailbox. It lives inside RabbitMQ.
  Although messages flow through RabbitMQ and your applications, they can be
  stored only inside a queue. A queue is not bound by any limits, it can store
  as many messages as you like ‒ it's essentially an infinite buffer. Many
  producers can send messages that go to one queue, many consumers can try to
  receive data from one queue.

* **Consumer** - Consuming has a similar meaning to receiving. A consumer is a
  program that mostly waits to receive messages.

Note that the producer, consumer, and broker do not have to reside on the same
machine; indeed in most applications they don't.


### Our Hello World App

Our "Hello world" won't be too complex ‒ we will send a message, receive it,
and then print it on the screen. To do so we need two programs:

1. one that sends a message, and
1. one that receives and prints it.

The producer sends messages to the "hello" queue. The consumer receives
messages from that queue.

#### Sending

Our first module, ``kt-sending.lfe``, will send a single message to the queue.
The first things we need to do is to establish a TCP connection with the
RabbitMQ server. With that in place, we will be able to create an AMQP channel.
Remember:

1. The connections takes care of protocol version negotiation and authentication
   and so on for us.
1. The channel is like a virtual connection inside the TCP connection, and it
   is over this that AMQP commands are issued.

This will be done with the following two functions:

```cl
(kanin-conn:start ...)
(kanin-conn:open-channel ...)
```

Before sending andy messages, we will need to make sure that the recipient
queue exists. If we send a message to non-existing location, RabbitMQ will just
trash the message. We will create the channal by sending a ``queue.declare``
record on our channel with ``(kanin-chan:call ...)``.

To send the message to the queue, we'll need to tell RabbitMQ the following:
 * the exchange we want to use,
 * the routing key to use, and then
 * the actual data

The first two will be used to create the "method", a ``basic.publish`` record.
The "message", an ``amqp_msg`` record, will hold the last bullet item. The
method and the message will be send with ``(kanin-chan:cast ...)``.

Finally, the channel and connection will be closed down with the following
calls:

```cl
(kanin-chan:close channel)
(kanin-conn:close connection)
```

The complete code for the module that encapsulates this logic is below:

```cl
(defmodule kt-sending
  (export all))

(include-lib "kanin/include/amqp-client.lfe")

(defun send ()
  (let* ((net-opts (make-amqp_params_network host "localhost"))
  		 ;; create the connection and channel we'll use for sending
         (`#(ok ,connection) (kanin-conn:start net-opts))
         (`#(ok ,channel) (kanin-conn:open-channel connection))
         ;; declare the names we will use
         (queue-name "hello")
         (routing-key "hello")
         (exchange-name "")
         (payload "Hello, world!")
         ;; then create the needed records
         (queue (make-queue.declare
                  queue (list_to_binary queue-name)))
         (method (make-basic.publish
                   exchange (list_to_binary exchange-name)
                   routing_key (list_to_binary routing-key)))
         (message (make-amqp_msg
                    payload (list_to_binary payload))))
    ;; perform the actual send
    (kanin-chan:call channel queue)
    (kanin-chan:cast channel method message)
    (io:format "[x] Sent message '~p'~n" `(,payload))
    ;; clean up
    (kanin-chan:close channel)
    (kanin-conn:close connection)))
```

Start up the REPL:

```bash
$ make repl-no-deps
Starting an LFE REPL ...
Erlang/OTP 17 [erts-6.2] [source] [64-bit] [smp:4:4] [async-threads:10] ...

LFE Shell V6.2 (abort with ^G)
```

Now you should be able to call your ``send`` function successfully:

```cl
> (kt-sending:send)
[x] Sent message '"Hello, world!"'
ok
>
```

That's it for our sender, but go ahead and keep a terminal window open with
this REPL running. We'll use it shortly.


#### Receiving

Our receiver gets messages pushed to it from RabbitMQ, so unlike the sender
which publishes a single message and then closes down, we'll keep the receiver
running to listen for in-coming messages and print them out.

As before, we will need to connect to RabbitMQ server, and the code for that is
the same as in the "send" section above. We will also define a queue and send
the ``queue.declare`` message, to ensure that is exists (this way, regardless
of whether the sender or the receiver starts first, the queue will exist for
either).

You can see the list of queues that exist on your host by issueing the
following command (as the same user who started up RabbitMQ):

```bash
$ /opt/rabbitmq/3.3.5/sbin/rabbitmqctl list_queues
```

This should give you output like the following:

```
Listing queues ...
hello	0
...done.
```

The next thing we'll need to do is set up the ``receive`` function process as
a subscriber, consuming messages from the queue we defined. This is done by
calling ``(kanin-chan:subscribe ...)``. To ensure that the subscription
succeeded, we'll listen for a ``basic.consume_ok`` response, and then set up
our message-receiving loop by calling ``(loop channel)``.

Our ``loop`` function will listen for data that matches a tuple of two records:
a ``basic.deliver`` record and an ``amqp_msg`` record. Whenever a message
matches, we'll display output to the terminal, and then start the loop
listening again.

The complete code for the module that encapsulates this logic is below:

```cl
(defmodule kt-receiving
  (export all))

(include-lib "kanin/include/amqp-client.lfe")

(defun receive ()
  (let* ((net-opts (make-amqp_params_network host "localhost"))
         ;; create the connection and channel we'll use for sending
         (`#(ok ,connection) (kanin-conn:start net-opts))
         (`#(ok ,channel) (kanin-conn:open-channel connection))
         ;; declare the names we will use
         (queue-name "hello")
         ;; define the data we will send
         (payload "Hello, world!")
         ;; then create the needed records
         (queue (make-queue.declare
                  queue (list_to_binary queue-name)))
         (consumer (make-basic.consume
                     queue (list_to_binary queue-name)
                     no_ack 'true))
         (subscriber (self)))
    ;; set up the queue
    (kanin-chan:call channel queue)
    (io:format "[*] Waiting for messages. To exit press CTRL+C~n")
    ;; subscribe the receive funtion to the queue
    (kanin-chan:subscribe channel consumer subscriber)
    ;; verify that the 'receive' function gets a successful result from
    ;; the previous (kanin-chan:subscribe ...) call
    (receive
      ((match-basic.consume_ok)
        'ok))
    ;; start listening for messages
    (loop channel)))

(defun loop (channel)
  ;; listen for a message that is a 2-tuple of two records: a basic.deliver
  ;; one, and an amqp_msg one
  (receive
    ((tuple (match-basic.deliver) (match-amqp_msg payload body))
      (io:format "[x] Received: ~p~n" `(,body))
      ;; restart the loop to listen for the next message
      (loop channel))))
```


#### Putting It Together

You should already have the "sending" code loaded up in a termainal window.
Open another one (be sure you are in the previously-created ``kanin-tutorials``
directory), and Start up the REPL:

```bash
$ make repl-no-deps
Starting an LFE REPL ...
Erlang/OTP 17 [erts-6.2] [source] [64-bit] [smp:4:4] [async-threads:10] ...

LFE Shell V6.2 (abort with ^G)
```

This will be your "receiving" terminal. Go ahead and start up the "receive"
loop:

```cl
> (kt-receiving:receive)
[*] Waiting for messages. To exit press CTRL+C
```

Switch back over to your "sending" terminal, and fire off four calls of the
``send`` function:

```cl
> (kt-sending:send)
[x] Sent message '"Hello, world!"'
ok
> (kt-sending:send)
[x] Sent message '"Hello, world!"'
ok
> (kt-sending:send)
[x] Sent message '"Hello, world!"'
ok
> (kt-sending:send)
[x] Sent message '"Hello, world!"'
ok
>
```

Switch back over to your "receiving" terminal, and you should see four messages
indicating proper receipt:

```cl
[x] Received: <<"Hello, world!">>
[x] Received: <<"Hello, world!">>
[x] Received: <<"Hello, world!">>
[x] Received: <<"Hello, world!">>
```


### Next Up

That's it for the "Hello World" tutorial. The next tutorial is one on
[Work Queues](./02-tutorial-work-queues.md). Or you can return to the
[tutorials index](./tutorials.md).
