;; PropTokens - Fractional Synthetic Ownership of Premium Real Estate Properties
;; Built on Stacks Blockchain using Clarity

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PROPERTY_NOT_FOUND (err u101))
(define-constant ERR_INSUFFICIENT_BALANCE (err u102))
(define-constant ERR_INVALID_AMOUNT (err u103))
(define-constant ERR_PROPERTY_ALREADY_EXISTS (err u104))
(define-constant ERR_TRANSFER_FAILED (err u105))

;; Data Variables
(define-data-var next-property-id uint u1)

;; Data Maps
(define-map properties
  { property-id: uint }
  {
    name: (string-ascii 100),
    location: (string-ascii 100),
    total-value: uint,
    total-supply: uint,
    price-per-token: uint,
    is-active: bool
  }
)

(define-map property-balances
  { property-id: uint, owner: principal }
  { balance: uint }
)

(define-map property-owners
  { property-id: uint }
  { owners: (list 100 principal) }
)

;; SIP-010 Token Trait Implementation for each property
(define-fungible-token prop-token)

;; Read-only functions
(define-read-only (get-property-info (property-id uint))
  (map-get? properties { property-id: property-id })
)

(define-read-only (get-balance (property-id uint) (owner principal))
  (default-to u0 
    (get balance (map-get? property-balances { property-id: property-id, owner: owner }))
  )
)

(define-read-only (get-total-properties)
  (- (var-get next-property-id) u1)
)

(define-read-only (get-property-owners (property-id uint))
  (map-get? property-owners { property-id: property-id })
)

(define-read-only (calculate-ownership-percentage (property-id uint) (owner principal))
  (let (
    (balance (get-balance property-id owner))
    (property-info (unwrap! (get-property-info property-id) u0))
    (total-supply (get total-supply property-info))
  )
    (if (is-eq total-supply u0)
      u0
      (/ (* balance u10000) total-supply) ;; Returns percentage * 100 (e.g., 1500 = 15.00%)
    )
  )
)

;; Public functions

;; Create a new property for tokenization
(define-public (create-property 
  (name (string-ascii 100))
  (location (string-ascii 100))
  (total-value uint)
  (total-supply uint))
  (let (
    (property-id (var-get next-property-id))
    (price-per-token (/ total-value total-supply))
  )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (> total-supply u0) ERR_INVALID_AMOUNT)
    (asserts! (> total-value u0) ERR_INVALID_AMOUNT)
    
    (map-set properties
      { property-id: property-id }
      {
        name: name,
        location: location,
        total-value: total-value,
        total-supply: total-supply,
        price-per-token: price-per-token,
        is-active: true
      }
    )
    
    (var-set next-property-id (+ property-id u1))
    (ok property-id)
  )
)

;; Purchase property tokens
(define-public (buy-tokens (property-id uint) (amount uint))
  (let (
    (property-info (unwrap! (get-property-info property-id) ERR_PROPERTY_NOT_FOUND))
    (price-per-token (get price-per-token property-info))
    (total-cost (* amount price-per-token))
    (current-balance (get-balance property-id tx-sender))
  )
    (asserts! (get is-active property-info) ERR_PROPERTY_NOT_FOUND)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    
    ;; Transfer STX from buyer to contract
    (try! (stx-transfer? total-cost tx-sender (as-contract tx-sender)))
    
    ;; Update buyer's balance
    (map-set property-balances
      { property-id: property-id, owner: tx-sender }
      { balance: (+ current-balance amount) }
    )
    
    ;; Add to property owners list if not already present
    (if (is-eq current-balance u0)
      (update-property-owners property-id tx-sender)
      true
    )
    
    (ok amount)
  )
)

;; Transfer tokens between users
(define-public (transfer-tokens 
  (property-id uint)
  (amount uint)
  (sender principal)
  (recipient principal))
  (let (
    (sender-balance (get-balance property-id sender))
  )
    (asserts! (is-eq tx-sender sender) ERR_UNAUTHORIZED)
    (asserts! (>= sender-balance amount) ERR_INSUFFICIENT_BALANCE)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    
    ;; Update sender balance
    (map-set property-balances
      { property-id: property-id, owner: sender }
      { balance: (- sender-balance amount) }
    )
    
    ;; Update recipient balance
    (let ((recipient-balance (get-balance property-id recipient)))
      (map-set property-balances
        { property-id: property-id, owner: recipient }
        { balance: (+ recipient-balance amount) }
      )
      
      ;; Add recipient to property owners if not already present
      (if (is-eq recipient-balance u0)
        (update-property-owners property-id recipient)
        true
      )
    )
    
    (ok true)
  )
)

;; Sell tokens back to the contract
(define-public (sell-tokens (property-id uint) (amount uint))
  (let (
    (property-info (unwrap! (get-property-info property-id) ERR_PROPERTY_NOT_FOUND))
    (price-per-token (get price-per-token property-info))
    (total-payout (* amount price-per-token))
    (current-balance (get-balance property-id tx-sender))
  )
    (asserts! (get is-active property-info) ERR_PROPERTY_NOT_FOUND)
    (asserts! (>= current-balance amount) ERR_INSUFFICIENT_BALANCE)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    
    ;; Update seller's balance
    (map-set property-balances
      { property-id: property-id, owner: tx-sender }
      { balance: (- current-balance amount) }
    )
    
    ;; Transfer STX from contract to seller
    (try! (as-contract (stx-transfer? total-payout tx-sender tx-sender)))
    
    (ok amount)
  )
)

;; Update property value (only owner)
(define-public (update-property-value (property-id uint) (new-value uint))
  (let (
    (property-info (unwrap! (get-property-info property-id) ERR_PROPERTY_NOT_FOUND))
    (total-supply (get total-supply property-info))
    (new-price-per-token (/ new-value total-supply))
  )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (> new-value u0) ERR_INVALID_AMOUNT)
    
    (map-set properties
      { property-id: property-id }
      (merge property-info {
        total-value: new-value,
        price-per-token: new-price-per-token
      })
    )
    
    (ok true)
  )
)

;; Deactivate property (only owner)
(define-public (deactivate-property (property-id uint))
  (let (
    (property-info (unwrap! (get-property-info property-id) ERR_PROPERTY_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    
    (map-set properties
      { property-id: property-id }
      (merge property-info { is-active: false })
    )
    
    (ok true)
  )
)

;; Private functions
(define-private (update-property-owners (property-id uint) (new-owner principal))
  (let (
    (current-owners-data (map-get? property-owners { property-id: property-id }))
  )
    (match current-owners-data
      owners-info
      (let ((current-owners (get owners owners-info)))
        (if (< (len current-owners) u100)
          (map-set property-owners
            { property-id: property-id }
            { owners: (unwrap! (as-max-len? (append current-owners new-owner) u100) false) }
          )
          false
        )
      )
      ;; First owner
      (map-set property-owners
        { property-id: property-id }
        { owners: (list new-owner) }
      )
    )
  )
)

;; Contract initialization
(begin
  (print "PropTokens contract deployed successfully")
)