(defpackage #:cl-v4l2-api
  (:use #:cl #:cffi #:iterate #:defmacro-enhance)
  (:shadowing-import-from
   #:v4l2-grovel
   ;; errnos
   #:eperm #:enoent #:esrch #:eintr #:eio #:enxio #:e2big #:enoexec #:ebadf #:echild #:eagain #:enomem #:eacces
   #:efault #:enotblk #:ebusy #:eexist #:exdev #:enodev #:enotdir #:eisdir #:einval #:enfile #:emfile #:enotty #:etxtbsy
   #:efbig #:enospc #:espipe #:erofs #:emlink #:epipe #:edom #:erange #:edeadlk #:enametoolong #:enolck #:enosys
   #:enotempty #:eloop #:ewouldblock #:enomsg #:eidrm #:echrng #:el2nsync #:el3hlt #:el3rst #:elnrng #:eunatch
   #:enocsi #:el2hlt #:ebade #:ebadr #:exfull #:enoano #:ebadrqc #:ebadslt #:edeadlock #:ebfont #:enostr #:enodata #:etime
   #:enosr #:enonet #:enopkg #:eremote #:enolink #:eadv #:esrmnt #:ecomm #:eproto #:emultihop #:ebadmsg #:eoverflow
   #:enotuniq #:ebadfd #:eremchg #:elibacc #:elibbad #:elibscn #:elibmax #:elibexec #:eilseq #:erestart #:estrpipe
   #:eusers #:enotsock #:edestaddrreq #:emsgsize #:eprototype #:enoprotoopt #:eprotonosupport #:esocktnosupport
   #:eopnotsupp #:epfnosupport #:eafnosupport #:eaddrinuse #:eaddrnotavail #:enetdown #:enetunreach #:enetreset
   #:econnaborted #:econnreset #:enobufs #:eisconn #:enotconn #:eshutdown #:etoomanyrefs #:etimedout #:econnrefused
   #:ehostdown #:ehostunreach #:ealready #:einprogress #:estale

   #:v4l2-capability
   #:vidioc-querycap
   #:o-rdwr
   #:o-nonblock
   #:driver
   #:card
   #:bus-info
   #:version
   #:capabilities
   #:reserved
   #:cap-video-capture #:cap-video-output #:cap-video-overlay #:cap-vbi-capture #:cap-vbi-output
   #:cap-sliced-vbi-capture #:cap-sliced-vbi-output #:cap-rds-capture #:cap-video-output-overlay
   #:cap-hw-freq-seek #:cap-tuner #:cap-audio #:cap-radio #:cap-readwrite #:cap-asyncio
   #:cap-streaming
   ;; input
   #:vidioc-enuminput #:v4l2-input
   #:index #:name #:type #:audioset #:tuner #:std #:status #:reserved
   #:input-type-tuner #:input-type-camera
   #:std-pal-b #:std-pal-b1 #:std-pal-g #:std-pal-h #:std-pal-i #:std-pal-d #:std-pal-d1
   #:std-pal-k #:std-pal-m #:std-pal-n #:std-pal-nc #:std-pal-60 #:std-ntsc-m #:std-ntsc-m-jp
   #:std-ntsc-443 #:std-ntsc-m-kr #:std-secam-b #:std-secam-d #:std-secam-g #:std-secam-h
   #:std-secam-k #:std-secam-k1 #:std-secam-l #:std-secam-lc #:std-atsc-8-vsb #:std-atsc-16-vsb
   #:std-pal-bg #:std-b #:std-gh #:std-pal-dk #:std-pal #:std-ntsc #:std-mn #:std-secam-dk
   #:std-dk #:std-secam #:std-525-60 #:std-625-50 #:std-unknown #:std-all

   #:in-st-no-power #:in-st-no-signal #:in-st-no-color #:in-st-hflip #:in-st-vflip #:in-st-no-h-lock
   #:in-st-color-kill #:in-st-no-sync #:in-st-no-equ #:in-st-no-carrier #:in-st-macrovision
   #:in-st-no-access #:in-st-vtr

   ;;output
   #:vidioc-enumoutput #:v4l2-output #:output-type-modulator #:output-type-analog
   #:output-type-analog-vga-overlay
   #:modulator #:std

   #:vidioc-g-input #:vidioc-s-input #:vidioc-g-output #:vidioc-s-output

   ;;audio
   #:vidioc-enumaudio #:v4l2-audio
   #:audcap-stereo #:audcap-avl #:audmode-avl
   #:capability #:mode
   #:vidioc-enumaudout #:v4l2-audioout
   #:vidioc-g-audio #:vidioc-s-audio #:vidioc-g-audout #:vidioc-s-audout
   ))
