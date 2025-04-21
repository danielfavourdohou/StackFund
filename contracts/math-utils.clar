;; math-utils.clar
;; Safe math operations and other utilities

;; Convert a uint to string (limited functionality)
(define-read-only (uint-to-ascii (value uint))
  (let ((digit (mod value u10))
        (rest (/ value u10)))
    (if (is-eq value u0)
        "0"
        (if (> rest u0)
            (concat (uint-to-ascii rest) (element-at "0123456789" digit))
            (element-at "0123456789" digit)))))

;; Safe addition
(define-read-only (safe-add (a uint) (b uint))
  (let ((result (+ a b)))
    (asserts! (>= result a) (err u500)) ;; Check for overflow
    result))

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

;; ;; Convert a uint to string (limited functionality)
;; (define-read-only (uint-to-ascii (value uint))
;;   (let ((digit (mod value u10))
;;         (rest (/ value u10)))
;;     (if (is-eq value u0)
;;         "0"
;;         (if (> rest u0)
;;             (concat (uint-to-ascii rest) (unwrap-panic (element-at "0123456789" digit)))
;;             (unwrap-panic (element-at "0123456789" digit))))))