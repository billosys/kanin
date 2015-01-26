(defmodule kanin-util
  (export all))

(defun get-kanin-version ()
  (lutil:get-app-version 'kanin))

(defun get-versions ()
  (++ (lutil:get-versions)
      `(#(kanin ,(get-kanin-version)))))
