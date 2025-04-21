;; math-utils.clar
;; Safe math operations and other utilities

;; Convert a uint to string (hardcoded for common values)
(define-read-only (uint-to-ascii (value uint))
  (if (<= value u9)
      ;; Single digit
      (unwrap-panic (element-at "0123456789" value))
      (if (<= value u99)
          ;; Two digits
          (concat (unwrap-panic (element-at "0123456789" (/ value u10)))
                 (unwrap-panic (element-at "0123456789" (mod value u10))))
          (if (<= value u999)
              ;; Three digits
              (concat (unwrap-panic (element-at "0123456789" (/ value u100)))
                     (concat (unwrap-panic (element-at "0123456789" (/ (mod value u100) u10)))
                            (unwrap-panic (element-at "0123456789" (mod value u10)))))
              ;; Four digits (up to 9999)
              (concat (unwrap-panic (element-at "0123456789" (/ value u1000)))
                     (concat (unwrap-panic (element-at "0123456789" (/ (mod value u1000) u100)))
                            (concat (unwrap-panic (element-at "0123456789" (/ (mod value u100) u10)))
                                   (unwrap-panic (element-at "0123456789" (mod value u10))))))))))

;; Safe addition
(define-read-only (safe-add (a uint) (b uint))
  (let ((result (+ a b)))
    (if (>= result a)
        result
        u0)))

;; Safe subtraction
(define-read-only (safe-sub (a uint) (b uint))
  (if (>= a b)
      (- a b)
      u0)) ;; If b > a, return 0 instead of underflow

;; Calculate percentage
(define-read-only (percentage-of (amount uint) (percentage uint))
  (/ (* amount percentage) u100))

;; Check if value is between min and max (inclusive)
(define-read-only (is-between (value uint) (min uint) (max uint))
  (and (>= value min) (<= value max)))

;; Calculate fee amount
(define-read-only (calculate-fee (amount uint) (fee-percentage uint))
  (percentage-of amount fee-percentage))

;; Check if a goal amount has been reached
(define-read-only (goal-reached (current-amount uint) (goal-amount uint))
  (>= current-amount goal-amount))

;; Remaining amount to reach goal
(define-read-only (remaining-to-goal (current-amount uint) (goal-amount uint))
  (if (>= current-amount goal-amount)
      u0
      (- goal-amount current-amount)))

