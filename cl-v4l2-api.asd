;;;; ffi-tutorials.asd

(eval-when (:compile-toplevel :load-toplevel :execute)
  (asdf:oos 'asdf:load-op :cffi-grovel))

(asdf:defsystem #:cl-v4l2-api
  :serial t
  :description "Bindings for v4l2 API."
  :author "Alexander Popolitov <popolit@yandex-team.ru>"
  :license "GPLv3"
  :depends-on (#:cffi #:cffi-grovel #:iterate #:cl-interpol #:defmacro-enhance)
  :components ((:file "package-grovel")
	       (cffi-grovel:grovel-file "v4l2-grovelling")
	       (:file "package")
	       (:file "api")))

