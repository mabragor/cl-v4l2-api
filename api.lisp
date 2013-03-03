(in-package cl-v4l2-api)

(cl-interpol:enable-interpol-syntax)

(defcfun ("open" %posix-open) :int
  (device :pointer)
  (flags :int))

(defun logor (x y)
  (lognot (lognor x y)))

(defmacro! wrap-1 (funcall)
  "Wraps return value -1 into signalling of SYSCALL-ERROR."
  `(let ((,g!-res ,funcall))
     (if (equal ,g!-res -1)
	 (signal-syscall-error ',(car funcall))
	 ,g!-res)))

(defun posix-open (device &rest flags)
  (with-foreign-string (device device)
    (wrap-1 (%posix-open device (reduce #'logor flags)))))

(defun v4l2-open (dev-num)
  (posix-open #?"/dev/video$(dev-num)" o-rdwr))

(define-condition syscall-error (simple-condition error)
  ((errno :initarg :errno :accessor syscall-errno))
  (:documentation "Condition signalled when syscal fails."))

(defparameter errnos
  '(eperm enoent esrch eintr eio enxio e2big enoexec ebadf echild eagain enomem eacces efault enotblk ebusy eexist exdev
    enodev enotdir eisdir einval enfile emfile enotty etxtbsy efbig enospc espipe erofs emlink epipe edom erange edeadlk
    enametoolong enolck enosys enotempty eloop ewouldblock enomsg eidrm echrng el2nsync el3hlt el3rst elnrng eunatch
    enocsi el2hlt ebade ebadr exfull enoano ebadrqc ebadslt edeadlock ebfont enostr enodata etime enosr enonet enopkg
    eremote enolink eadv esrmnt ecomm eproto emultihop ebadmsg eoverflow enotuniq ebadfd eremchg elibacc elibbad elibscn
    elibmax elibexec eilseq erestart estrpipe eusers enotsock edestaddrreq emsgsize eprototype enoprotoopt eprotonosupport
    esocktnosupport eopnotsupp epfnosupport eafnosupport eaddrinuse eaddrnotavail enetdown enetunreach enetreset
    econnaborted econnreset enobufs eisconn enotconn eshutdown etoomanyrefs etimedout econnrefused ehostdown ehostunreach 
    ealready einprogress estale))

(defparameter errno-names (mapcar (lambda (x) 
				    `(,(symbol-value x) . ,(intern (string x) :keyword)))
				  errnos))

(defun errno-name (errno)
  (or (cdr (assoc errno errno-names :test #'equal))
      ":UNKNOWN"))

(defun signal-syscall-error (syscall &optional (errno (sb-unix::get-errno)))
  (error 'syscall-error
	 :format-control "Syscall ~a failed with errno ~a (~a)."
	 :format-arguments `(,(string-upcase syscall) ,errno ,(errno-name errno))
	 :errno errno))
  
(defcfun ("close" %posix-close) :int (fd :int))
(defun posix-close (fd)
  (wrap-1 (%posix-close fd)))

(defcfun ("ioctl" %posix-ioctl) :int
  (fd :int)
  (request :uint32)
  (dest-struct :pointer))

(defun posix-ioctl (fd request argp)
  (wrap-1 (%posix-ioctl fd request argp)))

(defun format-version (version)
  (format nil "~{~a~^.~}"
	  (mapcar (lambda (x)
		    (logand (ash version (- x)) #xff))
		  '(16 8 0))))

(defun querycap (fd)
  (with-foreign-object (caps 'v4l2-capability)
    (posix-ioctl fd vidioc-querycap caps)
    (with-foreign-slots
	((driver card bus-info version
		 capabilities)
	 caps v4l2-capability)
      (list (foreign-string-to-lisp driver)
	    (foreign-string-to-lisp card)
	    (foreign-string-to-lisp bus-info)
	    (format-version version)
	    (parse-flag-field capabilities capability-flags)))))

(defparameter capability-flags
  '(cap-video-capture cap-video-output cap-video-overlay cap-vbi-capture cap-vbi-output
    cap-sliced-vbi-capture cap-sliced-vbi-output cap-rds-capture cap-video-output-overlay
    cap-hw-freq-seek cap-tuner cap-audio cap-radio cap-readwrite cap-asyncio cap-streaming))

(defun parse-flag-field (caps list-of-flags)
  (iter (for flag in list-of-flags)
	(if (not (zerop (logand caps (symbol-value flag))))
	    (collect (intern (string flag) :keyword)))))

(defparameter standard-flags
  '(std-pal-b std-pal-b1 std-pal-g std-pal-h std-pal-i std-pal-d std-pal-d1
    std-pal-k std-pal-m std-pal-n std-pal-nc std-pal-60 std-ntsc-m std-ntsc-m-jp
    std-ntsc-443 std-ntsc-m-kr std-secam-b std-secam-d std-secam-g std-secam-h
    std-secam-k std-secam-k1 std-secam-l std-secam-lc std-atsc-8-vsb std-atsc-16-vsb
    std-pal-bg std-b std-gh std-pal-dk std-pal std-ntsc std-mn std-secam-dk
    std-dk std-secam std-525-60 std-625-50 std-unknown std-all))

(defparameter input-status-flags
  '(in-st-no-power in-st-no-signal in-st-no-color in-st-hflip in-st-vflip in-st-no-h-lock
    in-st-color-kill in-st-no-sync in-st-no-equ in-st-no-carrier in-st-macrovision
    in-st-no-access in-st-vtr))

(defmacro! iterate-over-indices ((var type ioctl) &body body)
  "Captures FD from enclosing environment.
Useful in writing ENUM* functions."
  `(with-foreign-object (,var ',type)
     (iter (for ,g!-i from 0)
	   (setf (foreign-slot-value ,var ',type 'index) ,g!-i)
	   (handler-case (posix-ioctl fd ,ioctl ,var)
	     (syscall-error (e) (if (eql (errno-name (syscall-errno e)) :einval)
				    (terminate)
				    (error e))))
	   ,@body)))


(defun enuminput (fd)
  (iterate-over-indices (input v4l2-input vidioc-enuminput)
    (with-foreign-slots
	((index name type audioset tuner std status) input v4l2-input)
      (collect (list index
		     (foreign-string-to-lisp name)
		     (cond
		       ((equal type input-type-tuner) :input-type-tuner)
		       ((equal type input-type-camera) :input-type-camera))
		     (bitmask-to-bit-nums audioset 32)
		     tuner
		     (parse-flag-field std standard-flags)
		     (parse-flag-field status input-status-flags)
		     )))))

(defun enumoutput (fd)
  (iterate-over-indices (output v4l2-output vidioc-enumoutput)
    (with-foreign-slots
	((index name type audioset modulator std) output v4l2-output)
      (collect (list index
		     (foreign-string-to-lisp name)
		     (cond
		       ((equal type output-type-modulator) :output-type-modulator)
		       ((equal type output-type-analog) :output-type-analog)
		       ((equal type output-type-analog-vga-overlay) :output-type-analog-vga-overlay))
		     (bitmask-to-bit-nums audioset 32)
		     modulator
		     (parse-flag-field std standard-flags))))))

(defun bitmask-to-bit-nums (number nbits)
  (iter (for i from 0 below nbits)
	(if (not (zerop (logand number (expt 2 i))))
	    (collect i))))

(defun video-get-input (fd)
  (with-foreign-object (argp '(:pointer :int))
    (posix-ioctl fd vidioc-g-input argp)
    (mem-ref argp :int)))

(defun video-set-input (fd val)
  (with-foreign-object (argp '(:pointer :int))
    (setf (mem-ref argp :int) val)
    (posix-ioctl fd vidioc-s-input argp)))

(defun video-input (fd)
  (video-get-input fd))

(defsetf video-input (fd) (val)
  `(progn (video-set-input ,fd ,val)
	  ,val))

(defun video-get-output (fd)
  (with-foreign-object (argp '(:pointer :int))
    (posix-ioctl fd vidioc-g-output argp)
    (mem-ref argp :int)))

(defun video-set-output (fd val)
  (with-foreign-object (argp '(:pointer :int))
    (setf (mem-ref argp :int) val)
    (posix-ioctl fd vidioc-s-output argp)))

(defun video-output (fd)
  (video-get-output fd))

(defsetf video-output (fd) (val)
  `(progn (video-set-output ,fd ,val)
	  ,val))

(defparameter audcap-flags
  '(audcap-stereo audcap-avl))

(defparameter audmode-flags '(audmode-avl))

(defun enumaudio (fd)
  (iterate-over-indices (audio v4l2-audio vidioc-enumaudio)
    (with-foreign-slots
	((index name capability mode) audio v4l2-audio)
      (collect (list index
		     (foreign-string-to-lisp name)
		     (parse-flag-field capability audcap-flags)
		     (parse-flag-field mode audmode-flags))))))

(defparameter audoutcap-flags '())
(defparameter audoutmode-flags '())
(defun enumaudout (fd)
  (iterate-over-indices (audio v4l2-audioout vidioc-enumaudout)
    (with-foreign-slots
	((index name capability mode) audio v4l2-audio)
      (collect (list index
		     (foreign-string-to-lisp name)
		     (parse-flag-field capability audoutcap-flags)
		     (parse-flag-field mode audoutmode-flags))))))

(defun audio-get-input (fd)
  (with-foreign-object (argp 'v4l2-audio)
    (setf (mem-ref (foreign-slot-value argp 'v4l2-audio 'reserved) :int 0) 0
	  (mem-ref (foreign-slot-value argp 'v4l2-audio 'reserved) :int 1) 0)
    (posix-ioctl fd vidioc-g-audio argp)
    (with-foreign-slots
	((index name capability mode) argp v4l2-audio)
      (list index
	    (foreign-string-to-lisp name)
	    (parse-flag-field capability audcap-flags)
	    (parse-flag-field mode audmode-flags)))))
(defun audio-get-output (fd)
  (with-foreign-object (argp 'v4l2-audioout)
    (setf (mem-ref (foreign-slot-value argp 'v4l2-audio 'reserved) :int 0) 0
	  (mem-ref (foreign-slot-value argp 'v4l2-audio 'reserved) :int 1) 0)
    (posix-ioctl fd vidioc-g-audout argp)
    (with-foreign-slots
	((index name capability mode) argp v4l2-audioout)
      (list index
	    (foreign-string-to-lisp name)
	    (parse-flag-field capability audcap-flags)
	    (parse-flag-field mode audmode-flags)))))
;; do not want to implement setters for now, as my camera actually has no audio devices.

;; I'll skip TUNERS and MODULATORS for now, also.

