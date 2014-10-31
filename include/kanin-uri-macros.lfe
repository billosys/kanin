(eval-when-compile

  (defun get-api-funcs ()
    '(;(parse 1) (parse 2)
      (remove-credentials 1))))

(defmacro generate-api ()
  `(progn ,@(kla:make-funcs (get-api-funcs) 'amqp_uri)))

(generate-api)
