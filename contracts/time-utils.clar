;; time-utils.clar
;; Time and block-related utilities

;; Constants for time calculations
(define-constant SECONDS-PER-MINUTE u60)
(define-constant SECONDS-PER-HOUR (* SECONDS-PER-MINUTE u60))
(define-constant SECONDS-PER-DAY (* SECONDS-PER-HOUR u24))
(define-constant SECONDS-PER-WEEK (* SECONDS-PER-DAY u7))
(define-constant SECONDS-PER-MONTH (* SECONDS-PER-DAY u30))

;; Get current time - using a data var for testing
(define-data-var current-block-height uint u0)

;; Get current time
(define-read-only (get-current-time)
  (var-get current-block-height))

;; Set current time (for testing)
(define-public (set-current-time (new-time uint))
  (begin
    (var-set current-block-height new-time)
    (ok true)))

;; Add duration to current time
(define-read-only (add-duration-to-now (duration uint))
  (+ (get-current-time) duration))

;; Add specific time units to a timestamp
(define-read-only (add-minutes (timestamp uint) (minutes uint))
  (+ timestamp (* minutes SECONDS-PER-MINUTE)))

(define-read-only (add-hours (timestamp uint) (hours uint))
  (+ timestamp (* hours SECONDS-PER-HOUR)))

(define-read-only (add-days (timestamp uint) (days uint))
  (+ timestamp (* days SECONDS-PER-DAY)))

(define-read-only (add-weeks (timestamp uint) (weeks uint))
  (+ timestamp (* weeks SECONDS-PER-WEEK)))

;; Check if a deadline has passed
(define-read-only (deadline-passed (deadline uint))
  (> (get-current-time) deadline))

;; Calculate remaining time
(define-read-only (time-remaining (deadline uint))
  (if (> deadline (get-current-time))
      (- deadline (get-current-time))
      u0))

;; Convert blocks to estimated days
(define-read-only (blocks-to-days (blocks uint))
  (/ blocks u144)) ;; Assuming ~10 min per block, 144 blocks per day