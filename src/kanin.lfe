(defmodule kanin
  (export all))

(include-lib "amqp_lib/include/amqp_client.hrl")

(defun noop ()
  'noop)