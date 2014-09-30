(defmodule kanin
  (export all))

(include-lib "amqp_lib/amqp_client.hrl")

(defun noop ()
  'noop)