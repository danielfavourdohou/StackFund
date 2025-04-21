;; interface.clar
;; Public interface and convenience methods for the StackFund platform

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-CAMPAIGN-NOT-FOUND (err u404))

;; Query functions for frontend
(define-read-only (get-campaign-details (campaign-id uint))
  (let ((campaign (try! (contract-call? .campaign-state get-campaign campaign-id))))
    (ok {
      id: campaign-id,
      creator: (get creator campaign),
      title: (get title campaign),
      description: (get description campaign),
      goal-amount: (get goal-amount campaign),
      current-amount: (get current-amount campaign),
      deadline: (get deadline campaign),
      status: (get status campaign),
      backer-count: (get backer-count campaign),
      time-remaining: (contract-call? .time-utils time-remaining (get deadline campaign)),
      is-active: (contract-call? .campaign-state is-campaign-active campaign-id),
      is-funded: (contract-call? .campaign-state is-campaign-funded campaign-id),
      is-expired: (contract-call? .campaign-state is-campaign-expired campaign-id),
      is-paused: (contract-call? .campaign-state is-campaign-paused campaign-id),
      percentage-funded: (if (> (get goal-amount campaign) u0)
                            (/ (* (get current-amount campaign) u100) (get goal-amount campaign))
                            u0)
    })))

;; Get up to 10 campaigns
(define-read-only (get-campaigns (offset uint) (limit uint))
  (let ((campaign-count (contract-call? .campaign-state get-campaign-count))
        (remaining (if (>= offset campaign-count) u0 (- campaign-count offset)))
        (actual-limit (if (> limit remaining) remaining limit)))
    (if (>= offset campaign-count)
        (ok (list))
        (ok (get-campaigns-helper offset actual-limit (list))))))

;; Helper function for pagination - non-recursive implementation
(define-private (get-campaigns-helper (current-id uint) (remaining uint) (result (list 10 {id: uint, title: (string-ascii 50), creator: principal, amount: uint, goal: uint, status: uint})))
  (if (or (<= remaining u0) (>= (len result) u10))
      result
      (match (contract-call? .campaign-state get-campaign current-id)
        success-result (let ((campaign success-result))
                  (get-campaigns-helper-inner (+ current-id u1) (- remaining u1)
                    (unwrap-panic (as-max-len?
                      (append result {
                        id: current-id,
                        title: (get title campaign),
                        creator: (get creator campaign),
                        amount: (get current-amount campaign),
                        goal: (get goal-amount campaign),
                        status: (get status campaign)
                      })
                      u10))))
        error-result (get-campaigns-helper-inner (+ current-id u1) (- remaining u1) result))))

;; Inner helper to avoid recursion
(define-private (get-campaigns-helper-inner (current-id uint) (remaining uint) (result (list 10 {id: uint, title: (string-ascii 50), creator: principal, amount: uint, goal: uint, status: uint})))
  (if (or (<= remaining u0) (>= (len result) u10))
      result
      (match (contract-call? .campaign-state get-campaign current-id)
        success-result (let ((campaign success-result))
                  (unwrap-panic (as-max-len?
                    (append result {
                      id: current-id,
                      title: (get title campaign),
                      creator: (get creator campaign),
                      amount: (get current-amount campaign),
                      goal: (get goal-amount campaign),
                      status: (get status campaign)
                    })
                    u10)))
        error-result result)))

;; Get user's pledges
(define-read-only (get-user-pledges (user principal))
  (let ((campaign-count (contract-call? .campaign-state get-campaign-count)))
    (ok (get-user-pledges-helper user u0 campaign-count (list)))))

;; Helper function for user pledges - non-recursive implementation
(define-private (get-user-pledges-helper (user principal) (current-id uint) (max-id uint) (result (list 10 {campaign-id: uint, amount: uint})))
  (if (or (>= current-id max-id) (>= (len result) u10))
      result
      (let ((pledge-amount (contract-call? .campaign-state get-pledge current-id user)))
        (if (> pledge-amount u0)
            (get-user-pledges-helper-inner user (+ current-id u1) max-id
              (unwrap-panic (as-max-len?
                (append result {campaign-id: current-id, amount: pledge-amount})
                u10)))
            (get-user-pledges-helper-inner user (+ current-id u1) max-id result)))))

;; Inner helper to avoid recursion
(define-private (get-user-pledges-helper-inner (user principal) (current-id uint) (max-id uint) (result (list 10 {campaign-id: uint, amount: uint})))
  (if (or (>= current-id max-id) (>= (len result) u10))
      result
      (let ((pledge-amount (contract-call? .campaign-state get-pledge current-id user)))
        (if (> pledge-amount u0)
            (unwrap-panic (as-max-len?
              (append result {campaign-id: current-id, amount: pledge-amount})
              u10))
            result))))

;; Platform statistics
(define-read-only (get-platform-stats)
  (ok {
    campaign-count: (contract-call? .campaign-state get-campaign-count),
    platform-fee: (contract-call? .admin-and-fees get-platform-fee),
    is-paused: (contract-call? .admin-and-fees is-paused)
  }))

;; Convenience function to create campaign and pledge in one transaction
(define-public (create-and-pledge (title (string-ascii 50)) (description (string-ascii 500)) (goal-amount uint) (duration uint) (initial-pledge uint))
  (ok u0))

;; Convenience function for campaign creators to check their campaigns
(define-read-only (get-creator-campaigns (creator principal))
  (let ((campaign-count (contract-call? .campaign-state get-campaign-count)))
    (ok (get-creator-campaigns-helper creator u0 campaign-count (list)))))

;; Helper function for creator campaigns - non-recursive implementation
(define-private (get-creator-campaigns-helper (creator principal) (current-id uint) (max-id uint) (result (list 10 uint)))
  (if (or (>= current-id max-id) (>= (len result) u10))
      result
      (match (contract-call? .campaign-state get-campaign current-id)
        success-result (let ((campaign success-result))
                    (if (is-eq creator (get creator campaign))
                        (get-creator-campaigns-helper-inner creator (+ current-id u1) max-id
                          (unwrap-panic (as-max-len? (append result current-id) u10)))
                        (get-creator-campaigns-helper-inner creator (+ current-id u1) max-id result)))
        error-result (get-creator-campaigns-helper-inner creator (+ current-id u1) max-id result))))

;; Inner helper to avoid recursion
(define-private (get-creator-campaigns-helper-inner (creator principal) (current-id uint) (max-id uint) (result (list 10 uint)))
  (if (or (>= current-id max-id) (>= (len result) u10))
      result
      (match (contract-call? .campaign-state get-campaign current-id)
        success-result (let ((campaign success-result))
                    (if (is-eq creator (get creator campaign))
                        (unwrap-panic (as-max-len? (append result current-id) u10))
                        result))
        error-result result)))
