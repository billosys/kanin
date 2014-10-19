(defmodule kanin
  (export all))

;; XXX we can't use the comment-ed out code right now, due to a bug in
;; LFE that can't handle field-less records (which rabbit_framing.erl
;; has). Until that gets fixed, we're using a modified amqp-client that
;; works around this issue.
;;
;; (include-lib "amqp_lib/include/amqp_client.hrl")
(include-lib "kanin/include/amqp-client.lfe")

(defun noop ()
  'noop)
