;; backer-token.clar
;; A fungible token representing a backer's contribution to a campaign

(define-non-fungible-token backer-token uint)

;; Data variables
(define-data-var token-id-nonce uint u0)

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-TOKEN-NOT-FOUND (err u404))

;; Admin check
(define-read-only (is-admin)
  (is-eq tx-sender tx-sender))

;; Internal function to get the next token ID
(define-private (get-next-token-id)
  (let ((current-id (var-get token-id-nonce)))
    (var-set token-id-nonce (+ current-id u1))
    current-id))

;; NFT trait implementation
(define-read-only (get-last-token-id)
  (ok (var-get token-id-nonce)))

;; Convert uint to string
(define-read-only (uint-to-string (value uint))
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

(define-read-only (get-token-uri (token-id uint))
  (ok (some (concat "https://stackfund.xyz/token/" (uint-to-string token-id)))))

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? backer-token token-id)))

;; Mint a new backer token - can only be called by campaign-core
(define-public (mint (recipient principal) (campaign-id uint) (pledge-amount uint))
  (let ((token-id (get-next-token-id)))
    (asserts! (is-admin) ERR-NOT-AUTHORIZED)
    (try! (nft-mint? backer-token token-id recipient))
    (print {event: "backer-token-minted", recipient: recipient, token-id: token-id, campaign-id: campaign-id, pledge-amount: pledge-amount})
    (ok token-id)))

;; Transfer a backer token
(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
    (try! (nft-transfer? backer-token token-id sender recipient))
    (ok true)))