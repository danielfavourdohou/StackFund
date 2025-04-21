;; admin-and-fees.clar
;; Admin controls and fee management

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-INVALID-PARAMETER (err u400))

;; Data variables
(define-data-var admin principal tx-sender)
(define-data-var platform-fee-percentage uint u5) ;; 5% default fee
(define-data-var platform-treasury principal tx-sender)
(define-data-var emergency-pause bool false)

;; Read-only functions
(define-read-only (get-admin)
  (var-get admin))

(define-read-only (get-platform-fee)
  (var-get platform-fee-percentage))

(define-read-only (get-treasury)
  (var-get platform-treasury))

(define-read-only (is-paused)
  (var-get emergency-pause))

;; Admin authorization check
(define-private (is-admin)
  (is-eq tx-sender (var-get admin)))

;; Admin capabilities
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-admin) ERR-NOT-AUTHORIZED)
    (var-set admin new-admin)
    (ok true)))

(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-admin) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-fee u20) ERR-INVALID-PARAMETER) ;; Fee can't be more than 20%
    (var-set platform-fee-percentage new-fee)
    (ok true)))

(define-public (set-treasury (new-treasury principal))
  (begin
    (asserts! (is-admin) ERR-NOT-AUTHORIZED)
    (var-set platform-treasury new-treasury)
    (ok true)))

;; Emergency pause
(define-public (set-emergency-pause (paused bool))
  (begin
    (asserts! (is-admin) ERR-NOT-AUTHORIZED)
    (var-set emergency-pause paused)
    (ok true)))

;; Pause a specific campaign
(define-public (pause-campaign (campaign-id uint))
  (begin
    (asserts! (is-admin) ERR-NOT-AUTHORIZED)
    (try! (as-contract (contract-call? .campaign-state update-campaign-status campaign-id u4)))
    (ok true)))

;; Unpause a specific campaign
(define-public (unpause-campaign (campaign-id uint))
  (begin
    (asserts! (is-admin) ERR-NOT-AUTHORIZED)
    (try! (as-contract (contract-call? .campaign-state update-campaign-status campaign-id u1)))
    (ok true)))

;; Calculate fee for an amount
(define-read-only (calculate-fee (amount uint))
  (contract-call? .math-utils percentage-of amount (var-get platform-fee-percentage)))

;; Withdraw fees to treasury
(define-public (withdraw-fees (amount uint))
  (begin
    (asserts! (is-admin) ERR-NOT-AUTHORIZED)
    (try! (as-contract (stx-transfer? amount tx-sender (var-get platform-treasury))))
    (print {event: "fee-withdrawal", amount: amount, treasury: (var-get platform-treasury)})
    (ok true)))