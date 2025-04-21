;; campaign-state.clar
;; Defines the data structure and state for campaigns

;; Constants for campaign statuses
(define-constant STATUS-ACTIVE u1)
(define-constant STATUS-FUNDED u2)
(define-constant STATUS-EXPIRED u3)
(define-constant STATUS-PAUSED u4)

;; Error codes
(define-constant ERR-CAMPAIGN-NOT-FOUND (err u404))
(define-constant ERR-INVALID-STATUS (err u405))

;; Campaign data structure
(define-map campaigns uint {
  creator: principal,
  title: (string-ascii 50),
  description: (string-ascii 500),
  goal-amount: uint,
  current-amount: uint,
  deadline: uint,
  status: uint,
  backer-count: uint
})

;; Pledges tracking (campaign-id -> user -> amount)
(define-map pledges {campaign-id: uint, backer: principal} uint)

;; Campaign ID counter
(define-data-var campaign-id-nonce uint u0)

;; Getters
(define-read-only (get-campaign (campaign-id uint))
  (match (map-get? campaigns campaign-id)
    campaign (ok campaign)
    (err ERR-CAMPAIGN-NOT-FOUND)))

(define-read-only (get-pledge (campaign-id uint) (backer principal))
  (default-to u0 (map-get? pledges {campaign-id: campaign-id, backer: backer})))

(define-read-only (get-campaign-count)
  (var-get campaign-id-nonce))

;; Status checkers
(define-read-only (is-campaign-active (campaign-id uint))
  (match (map-get? campaigns campaign-id)
    campaign (is-eq (get status campaign) STATUS-ACTIVE)
    false))

(define-read-only (is-campaign-funded (campaign-id uint))
  (match (map-get? campaigns campaign-id)
    campaign (is-eq (get status campaign) STATUS-FUNDED)
    false))

(define-read-only (is-campaign-expired (campaign-id uint))
  (match (map-get? campaigns campaign-id)
    campaign (is-eq (get status campaign) STATUS-EXPIRED)
    false))

(define-read-only (is-campaign-paused (campaign-id uint))
  (match (map-get? campaigns campaign-id)
    campaign (is-eq (get status campaign) STATUS-PAUSED)
    false))

;; State modification functions (only available to campaign-core contract)
(define-public (create-campaign (creator principal) (title (string-ascii 50)) (description (string-ascii 500)) (goal-amount uint) (duration uint))
  (let ((current-id (var-get campaign-id-nonce))
        (deadline (contract-call? .time-utils add-duration-to-now duration)))
    (asserts! (is-eq contract-caller .campaign-core) (err u401))
    (map-set campaigns current-id {
      creator: creator,
      title: title,
      description: description,
      goal-amount: goal-amount,
      current-amount: u0,
      deadline: deadline,
      status: STATUS-ACTIVE,
      backer-count: u0
    })
    (var-set campaign-id-nonce (+ current-id u1))
    (ok current-id)))

(define-public (record-pledge (campaign-id uint) (backer principal) (amount uint))
  (let ((campaign (unwrap! (map-get? campaigns campaign-id) (err ERR-CAMPAIGN-NOT-FOUND)))
        (current-pledge (get-pledge campaign-id backer))
        (new-total-amount (+ (get current-amount campaign) amount))
        (new-backer-count (if (is-eq current-pledge u0)
                            (+ (get backer-count campaign) u1)
                            (get backer-count campaign))))
    (asserts! (is-eq contract-caller .campaign-core) (err u401))
    (map-set campaigns campaign-id (merge campaign {
      current-amount: new-total-amount,
      backer-count: new-backer-count
    }))
    (map-set pledges {campaign-id: campaign-id, backer: backer} (+ current-pledge amount))
    (ok true)))

(define-public (update-campaign-status (campaign-id uint) (new-status uint))
  (let ((campaign (unwrap! (map-get? campaigns campaign-id) (err ERR-CAMPAIGN-NOT-FOUND))))
    (asserts! (is-eq contract-caller .campaign-core) (err u401))
    (asserts! (or (is-eq new-status STATUS-ACTIVE)
                 (is-eq new-status STATUS-FUNDED)
                 (is-eq new-status STATUS-EXPIRED)
                 (is-eq new-status STATUS-PAUSED))
             ERR-INVALID-STATUS)
    (map-set campaigns campaign-id (merge campaign {status: new-status}))
    (ok true)))

(define-public (get-campaign-creator (campaign-id uint))
  (match (map-get? campaigns campaign-id)
    campaign (ok (get creator campaign))
    (err ERR-CAMPAIGN-NOT-FOUND)))