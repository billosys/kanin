# Kanin / RabbitMQ Tutorials

## Work Queues


### Introduction

In the [first tutorial](./01-tutorial-hello-world.md) we wrote programs to send
and receive messages from a named queue. In this one we'll create a *Work Queue*
that will be used to distribute time-consuming tasks among multiple workers.

The main idea behind Work Queues (aka: Task Queues) is to avoid doing a
resource-intensive task immediately and having to wait for it to complete.
Instead we schedule the task to be done later. We encapsulate a task as a
message and send it to the queue. A worker process running in the background
will pop the tasks and eventually execute the job. When you run many workers the
tasks will be shared between them.

This concept is especially useful in web applications where it's impossible to
handle a complex task during a short HTTP request window.


### Preparation

In the first tutorial we sent a message containing the string "Hello World!".
Now we'll be sending strings that stand for complex tasks. We don't have a real-
world task, like images to be resized or pdf files to be rendered, so let's fake
it by just pretending we're busy - by adding a timeout section to the
``(receive ...)`` part of our ``(loop ...)`` function. We'll take the number of
dots in the string as its complexity; every dot will account for one second of
"work". For example, a fake task described by ``Hello...`` will take three
seconds.

We will slightly modify the ``kt-sending.lfe`` code from our previous example,
to allow arbitrary messages to be sent from the command line. This program will
schedule tasks to our work queue, so let's name it ``kt-new-task.lfe``:

```cl
(defmodule kt-new-task
  (export all))

(include-lib "kanin/include/amqp-client.lfe")

(defun make-message
  (('())
    "Hello, world!")
  ((data)
    data))

(defun send ()
  (send '()))

(defun send (data)
  (let* ((net-opts (make-amqp_params_network host "localhost"))
         (`#(ok ,connection) (kanin-conn:start net-opts))
         (`#(ok ,channel) (kanin-conn:open-channel connection))
         (queue-name "task-queue")
         (routing-key "task-queue")
         (exchange-name "")
         (payload (make-message data))
         (queue (make-queue.declare
                  queue (list_to_binary queue-name)
                  durable 'true))
         (method (make-basic.publish
                   exchange (list_to_binary exchange-name)
                   routing_key (list_to_binary routing-key)))
         (message (make-amqp_msg
                    props (make-P_basic delivery_mode 2)
                    payload (list_to_binary payload))))
    (kanin-chan:call channel queue)
    (kanin-chan:cast channel method message)
    (io:format "[x] Sent message '~p'~n" `(,payload))
    (kanin-chan:close channel)
    (kanin-conn:close connection)))
```

Our old ``kt-receiving.lfe`` script also requires some changes: it needs to
fake a second of work for every dot in the message body. It will pop messages
from the queue and perform the task, so let's call it ``kt-worker.lfe``:

```cl
(defmodule kt-worker
  (export all))

(include-lib "kanin/include/amqp-client.lfe")

(defun receive ()
  (let* ((net-opts (make-amqp_params_network host "localhost"))
         (`#(ok ,connection) (kanin-conn:start net-opts))
         (`#(ok ,channel) (kanin-conn:open-channel connection))
         (queue-name "task-queue")
         (queue (make-queue.declare
                  queue (list_to_binary queue-name)
                  durable 'true))
         (qos (make-basic.qos prefetch_count 1))
         (consumer (make-basic.consume
                     queue (list_to_binary queue-name)))
         (subscriber (self)))
    (kanin-chan:call channel queue)
    (io:format "[*] Waiting for messages. To exit press CTRL+C~n")
    (kanin-chan:call channel qos)
    (kanin-chan:subscribe channel consumer subscriber)
    (receive
      ((match-basic.consume_ok)
        'ok))
    (loop channel)))

(defun get-dot-count (data)
  (length
    (list-comp
      ((<- char (binary_to_list data)) (== char #\.))
      char)))

(defun loop (channel)
  (receive
    ((tuple (match-basic.deliver delivery_tag tag)
            (match-amqp_msg payload body))
      (io:format "[x] Received: ~p~n" `(,body))
      (let ((dots (get-dot-count body)))
        (receive
          (after (* dots 1000)
            'ok))
        (io:format "[x] Done.~n"))
      (kanin-chan:cast channel (make-basic.ack delivery_tag tag))
      (loop channel))))
```


### Round-robin Dispatching

One of the advantages of using a Task Queue is the ability to easily parallelise
work. If we are building up a backlog of work, we can just add more workers and
that way, scale easily.

First, let's try to run two worker processes at the same time. They will both
get messages from the queue, but how exactly? Let's see.

You need three consoles open. Two will run the ``(receive)`` funtion in the
``kt-worker.lfe`` module. As such, these consoles will be two consumers.

```cl
$ make repl-no-deps
Starting an LFE REPL ...
Erlang/OTP 17 [erts-6.2] [source] [64-bit] [smp:4:4] [async-threads:10] ...

LFE Shell V6.2 (abort with ^G)
> (kt-worker:receive)
[*] Waiting for messages. To exit press CTRL+C
```

```cl
$ make repl-no-deps
Starting an LFE REPL ...
Erlang/OTP 17 [erts-6.2] [source] [64-bit] [smp:4:4] [async-threads:10] ...

LFE Shell V6.2 (abort with ^G)
> (kt-worker:receive)
[*] Waiting for messages. To exit press CTRL+C
```

In the third one we'll publish new tasks. Once you've started the consumers you
can publish a few messages:

```cl
> (kt-new-task:send)
[x] Sent message '"Hello, world!"'
ok
> (kt-new-task:send '())
[x] Sent message '"Hello, world!"'
ok
> (kt-new-task:send "Here's a third message")
[x] Sent message '"Here's a third message"'
ok
> (kt-new-task:send "Here's a fourth message")
[x] Sent message '"Here's a fourth message"'
ok
> (kt-new-task:send "Here's a fifth message")
[x] Sent message '"Here's a fifth message"'
ok
>
```

Let's see what is delivered to our workers. Here's the output we see in the
first terminal:

```
[x] Received: <<"Hello, world!">>
[x] Done.
[x] Received: <<"Here's a third message">>
[x] Done.
[x] Received: <<"Here's a fifth message">>
[x] Done.
```

And this is the output in the second terminal:

```
[x] Received: <<"Hello, world!">>
[x] Done.
[x] Received: <<"Here's a fourth message">>
[x] Done.
```

By default, RabbitMQ will send each message to the next consumer, in sequence.
On average every consumer will get the same number of messages. This way of
distributing messages is called round-robin. Try this out with three or more
workers.

Now let's simulate the complex tasks by inserting dots into our messages.
Head back to the "sending" terminal window:

```cl
> (kt-new-task:send "Message 1 ..........")
[x] Sent message '"Message 1 .........."'
ok
> (kt-new-task:send "Message 2 .........")
[x] Sent message '"Message 2 ........."'
ok
> (kt-new-task:send "Message 3 ........")
[x] Sent message '"Message 3 ........"'
ok
> (kt-new-task:send "Message 4 .......")
[x] Sent message '"Message 4 ......."'
ok
> (kt-new-task:send "Message 5 ......")
[x] Sent message '"Message 5 ......"'
ok
>
```

Output in the other terminals should be this:

```cl
[x] Received: <<"Message 1 ..........">>
[x] Done.
[x] Received: <<"Message 3 ........">>
[x] Done.
[x] Received: <<"Message 5 ......">>
[x] Done.
```

and this:

```cl
[x] Received: <<"Message 2 .........">>
[x] Done.
[x] Received: <<"Message 4 .......">>
[x] Done.
```

But the thing to notice here is that when sending these messgaes and checking
the output in the terminals, you should be seeing delays due to the complexity
simulation (timeouts on the ``(receive ...)``)


### Message Acknowledgment

Doing a task can take a few seconds. You may wonder what happens if one of the
consumers starts a long task and dies with it only partly done. With our current
code, once RabbitMQ delivers message to the consumer, it immediately removes it
from memory. In this case, if you kill a worker we will lose the message it was
just processing. We'll also lose all the messages that were dispatched to this
particular worker but were not yet handled.

But we don't want to lose any tasks. If a worker dies, we'd like the task to be
delivered to another worker.

In order to make sure a message is never lost, RabbitMQ supports message
acknowledgments. An ack(nowledgement) is sent back from the consumer to tell
RabbitMQ that a particular message had been received, processed and that
RabbitMQ is free to delete it.

If a consumer dies without sending an ack, RabbitMQ will understand that a
message wasn't processed fully and will redeliver it to another consumer. That
way you can be sure that no message is lost, even if the workers occasionally
die.

There aren't any message timeouts; RabbitMQ will redeliver the message only when
the worker connection dies. It's fine even if processing a message takes a very,
very long time.

Message acknowledgments are turned on by default. In previous examples we
explicitly turned them off via the no_ack=True flag. The careful observer will
have noticed that the ``consumer`` variable assignment in ``kt-worker.lfe``
removed the ``no_ack 'true`` parameter in the ``basic.consume`` record:

```cl
 (consumer (make-basic.consume
             queue (list_to_binary queue-name)))
```

We did this because we want to send a proper acknowledgment from the worker once
we're done with a task, as in the ``(loop ...)`` function:

```cl
(kanin-chan:cast channel (make-basic.ack delivery_tag tag))
```

Using this code we can be sure that even if you kill a worker using CTRL+C while
it was processing a message, nothing will be lost. Soon after the worker dies
all unacknowledged messages will be redelivered.

#### Forgotten acknowledgment

It's a common mistake to miss the basic_ack. It's an easy error, but the
consequences are serious. Messages will be redelivered when your client quits
(which may look like random redelivery), but RabbitMQ will eat more and more
memory as it won't be able to release any unacked messages.

In order to debug this kind of mistake you can use rabbitmqctl to print the
messages_unacknowledged field:

```bash
$ sudo rabbitmqctl list_queues name messages_ready messages_unacknowledged
Listing queues ...
hello    0       0
...done.
```


### Message Durability

We have learned how to make sure that even if the consumer dies, the task isn't
lost. But our tasks will still be lost if RabbitMQ server stops.

When RabbitMQ quits or crashes it will forget the queues and messages unless you
tell it not to. Two things are required to make sure that messages aren't lost:
we need to mark both the queue and messages as durable.

First, we need to make sure that RabbitMQ will never lose our queue. In order to
do so, we declared it as durable:

```cl
(queue (make-queue.declare
         queue (list_to_binary queue-name)
         durable 'true))
```

Note that we couldn't have set our old ``hello`` queue to durable once it had
already been created as non-durable. RabbitMQ doesn't allow you to redefine an
existing queue with different parameters and will return an error to any program
that tries to do that. So we just used a different name: ``task-queue``.

Note that we also made this change to both the producer and the consumer code.

Now we can be sure that the ``task-queue`` queue won't be lost, even if RabbitMQ
restarts. The next thing we needed to do in our quest for durability was to mark
our messages as persistent - by supplying a ``delivery_mode`` property with a
value 2:

```cl
(message (make-amqp_msg
           props (make-P_basic delivery_mode 2)
           payload (list_to_binary payload))))
```


#### Note on Message Persistence

Marking messages as persistent doesn't fully guarantee that a message won't be
lost. Although it tells RabbitMQ to save the message to disk, there is still a
short time window when RabbitMQ has accepted a message and hasn't saved it yet.
Also, RabbitMQ doesn't do ``fsync(2)`` for every message -- it may be just saved
to cache and not really written to the disk. The persistence guarantees aren't
strong, but it's more than enough for our simple task queue. If you need a
stronger guarantee then you can use **publisher confirms**.


### Fair dispatch

You might have noticed that the dispatching still doesn't work exactly as we
want. For example in a situation with two workers, when all odd messages are
heavy and even messages are light, one worker will be constantly busy and the
other one will do hardly any work. Well, RabbitMQ doesn't know anything about
that and will still dispatch messages evenly.

This happens because RabbitMQ just dispatches a message when the message enters
the queue. It doesn't look at the number of unacknowledged messages for a
consumer. It just blindly dispatches every n-th message to the n-th consumer.

In order to defeat that we can use the ``basic.qos`` method with the
prefetch_count=1 setting. This tells RabbitMQ not to give more than one message
to a worker at a time. Or, in other words, don't dispatch a new message to a
worker until it has processed and acknowledged the previous one. Instead, it
will dispatch it to the next worker that is not still busy:

```cl
(qos (make-basic.qos prefetch_count 1))
```

#### Note about Queue Size

If all the workers are busy, your queue can fill up. You will want to keep an
eye on that, and maybe add more workers, or have some other strategy.


### Next Up

That's it for the "Work Queues" tutorial. The next tutorial is one on
[Publish/Subscribe](./03-tutorial-pubsub.md). Or you can return to the
[tutorials index](./tutorials.md).
