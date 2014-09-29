(defmodule kanin-util
  (export all))

(defun get-kanin-version ()
  (lutil:get-app-src-version "src/kanin.app.src"))

(defun get-versions ()
  (++ (lutil:get-version)
      `(#(kanin ,(get-kanin-version)))))
