;; campaign-core.clar
;; Core business logic for campaign management

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-CAMPAIGN-NOT-FOUND (err u404))
(define-constant ERR-ALREADY-PLEDGED (err u409))
(define-constant ERR-INVALID-STATUS (err u410))
(define-constant ERR-DEADLINE-NOT-PASSED (err u411))
(define-constant ERR-GOAL-NOT-REACHED (err u412))
(define-constant ERR-SYSTEM-PAUSED (err u413))
(define-constant ERR-TRANSFER-FAILED (err u500))

;; Create a new campaign
(define-public (create-campaign (title (string-ascii 50)) (description (string-ascii 500)) (goal-amount uint) (duration uint))
  (begin
    (asserts! (not (contract-call? .admin-and-fees is-paused)) ERR-SYSTEM-PAUSED)
    (asserts! (> goal-amount u0) (err u400))
    (asserts! (> duration u0) (err u400))

    (let ((campaign-id (try! (contract-call? .campaign-state create-campaign tx-sender title description goal-amount duration))))
      (print {event: "campaign-created", campaign-id: campaign-id, creator: tx-sender, goal: goal-amount, duration: duration})
      (ok campaign-id))))

;; Pledge funds to a campaign
(define-public (pledge (campaign-id uint) (amount uint))
  (let ((campaign (try! (contract-call? .campaign-state get-campaign campaign-id)))
        (fee-amount (contract-call? .admin-and-fees calculate-fee amount))
        (pledge-amount (- amount fee-amount)))

    (asserts! (not (contract-call? .admin-and-fees is-paused)) ERR-SYSTEM-PAUSED)
    (asserts! (is-eq (get status campaign) .campaign-state STATUS-ACTIVE) ERR-INVALID-STATUS)
    (asserts! (not (contract-call? .time-utils deadline-passed (get deadline campaign))) ERR-INVALID-STATUS)

    ;; Transfer STX to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

    ;; Record the pledge
    (try! (as-contract (contract-call? .campaign-state record-pledge campaign-id tx-sender pledge-amount)))

    ;; Transfer fee to treasury
    (when (> fee-amount u0)
      (as-contract (stx-transfer? fee-amount tx-sender (contract-call? .admin-and-fees get-treasury))))

    (print {event: "pledge", campaign-id: campaign-id, backer: tx-sender, amount: pledge-amount, fee: fee-amount})
    (ok true)))

;; Finalize a campaign if goal reached
(define-public (finalize-campaign (campaign-id uint))
  (let ((campaign (try! (contract-call? .campaign-state get-campaign campaign-id))))

    (asserts! (not (contract-call? .admin-and-fees is-paused)) ERR-SYSTEM-PAUSED)
    (asserts! (is-eq (get status campaign) .campaign-state STATUS_ACTIVE) ERR-INVALID-STATUS)
    (asserts! (contract-call? .time-utils deadline-passed (get deadline campaign)) ERR-DEADLINE-NOT-PASSED)

    (if (contract-call? .math-utils goal-reached (get current-amount campaign) (get goal-amount campaign))
        ;; Goal reached - transfer funds to creator and update status
        (begin
          (try! (as-contract (stx-transfer? (get current-amount campaign) tx-sender (get creator campaign))))
          (try! (as-contract (contract-call? .campaign-state update-campaign-status campaign-id .campaign-state STATUS-FUNDED)))
          (print {event: "campaign-finalized", campaign-id: campaign-id, status: "funded", amount: (get current-amount campaign)})
          (ok true))
        ;; Goal not reached - update status to expired (refunds handled separately)
        (begin
          (try! (as-contract (contract-call? .campaign-state update-campaign-status campaign-id .campaign-state STATUS-EXPIRED)))
          (print {event: "campaign-finalized", campaign-id: campaign-id, status: "expired"})
          (ok true)))))

;; Request a refund if campaign expired (goal not reached)
(define-public (refund (campaign-id uint))
  (let ((campaign (try! (contract-call? .campaign-state get-campaign campaign-id)))
        (pledge-amount (contract-call? .campaign-state get-pledge campaign-id tx-sender)))

    (asserts! (not (contract-call? .admin-and-fees is-paused)) ERR-SYSTEM-PAUSED)
    (asserts! (is-eq (get status campaign) .campaign-state STATUS-EXPIRED) ERR-INVALID-STATUS)
    (asserts! (> pledge-amount u0) ERR-NOT-AUTHORIZED)

    ;; Transfer refund
    (try! (as-contract (stx-transfer? pledge-amount tx-sender tx-sender)))

    ;; Reset pledge record
    (try! (as-contract (contract-call? .campaign-state record-pledge campaign-id tx-sender u0)))

    (print {event: "refund", campaign-id: campaign-id, backer: tx-sender, amount: pledge-amount})
    (ok true)))

;; Mint backer tokens for successful campaign
(define-public (mint-backer-token (campaign-id uint))
  (let ((campaign (try! (contract-call? .campaign-state get-campaign campaign-id)))
        (pledge-amount (contract-call? .campaign-state get-pledge campaign-id tx-sender)))

    (asserts! (not (contract-call? .admin-and-fees is-paused)) ERR-SYSTEM-PAUSED)
    (asserts! (is-eq (get status campaign) .campaign-state STATUS-FUNDED) ERR-INVALID-STATUS)
    (asserts! (> pledge-amount u0) ERR-NOT-AUTHORIZED)

    (let ((token-id (try! (as-contract (contract-call? .backer-token mint tx-sender campaign-id pledge-amount)))))
      (print {event: "token-minted", campaign-id: campaign-id, backer: tx-sender, token-id: token-id})
      (ok token-id))))