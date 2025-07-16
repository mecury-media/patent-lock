;; Patent-Lock: Intellectual Property Smart Contract
;; A comprehensive IP registration and protection system on Stacks blockchain

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-EXISTS (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-EXPIRED (err u103))
(define-constant ERR-INVALID-PARAMETERS (err u104))
(define-constant ERR-TRANSFER-FAILED (err u105))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u106))

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant IP-REGISTRATION-FEE u1000000) ;; 1 STX in microSTX
(define-constant IP-RENEWAL-FEE u500000) ;; 0.5 STX in microSTX
(define-constant IP-VALIDITY-PERIOD u52560000) ;; ~10 years in blocks (assuming 10 min blocks)

;; Data structures
(define-map intellectual-properties
  { ip-id: uint }
  {
    owner: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    ip-type: (string-ascii 20), ;; "patent", "trademark", "copyright", "trade-secret"
    hash: (buff 32), ;; SHA256 hash of the IP content
    registration-block: uint,
    expiry-block: uint,
    status: (string-ascii 20), ;; "active", "expired", "revoked"
    license-terms: (string-ascii 200)
  }
)

(define-map ip-licenses
  { ip-id: uint, licensee: principal }
  {
    licensor: principal,
    license-type: (string-ascii 20), ;; "exclusive", "non-exclusive", "limited"
    start-block: uint,
    end-block: uint,
    royalty-rate: uint, ;; basis points (e.g., 500 = 5%)
    terms: (string-ascii 200),
    active: bool
  }
)

(define-map ip-disputes
  { dispute-id: uint }
  {
    ip-id: uint,
    challenger: principal,
    owner: principal,
    dispute-type: (string-ascii 30), ;; "infringement", "validity", "ownership"
    evidence-hash: (buff 32),
    status: (string-ascii 20), ;; "pending", "resolved", "dismissed"
    filed-block: uint,
    resolved-block: (optional uint)
  }
)

;; Data variables
(define-data-var next-ip-id uint u1)
(define-data-var next-dispute-id uint u1)
(define-data-var contract-balance uint u0)

;; Maps to track existence by hash to prevent duplicates
(define-map ip-hash-registry
  { content-hash: (buff 32) }
  { ip-id: uint, owner: principal }
)

;; Private functions
(define-private (is-valid-ip-type (ip-type (string-ascii 20)))
  (or (is-eq ip-type "patent")
      (is-eq ip-type "trademark")
      (is-eq ip-type "copyright")
      (is-eq ip-type "trade-secret"))
)

(define-private (is-ip-owner (ip-id uint) (user principal))
  (match (map-get? intellectual-properties { ip-id: ip-id })
    ip-data (is-eq (get owner ip-data) user)
    false
  )
)

(define-private (is-ip-active (ip-id uint))
  (match (map-get? intellectual-properties { ip-id: ip-id })
    ip-data (and (is-eq (get status ip-data) "active")
                 (> (get expiry-block ip-data) block-height))
    false
  )
)

(define-private (calculate-royalty (amount uint) (rate uint))
  (/ (* amount rate) u10000)
)

;; Public functions

;; Register new intellectual property
(define-public (register-ip 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (ip-type (string-ascii 20))
  (content-hash (buff 32))
  (license-terms (string-ascii 200))
)
  (let (
    (ip-id (var-get next-ip-id))
    (registration-block block-height)
    (expiry-block (+ block-height IP-VALIDITY-PERIOD))
  )
    ;; Validate inputs
    (asserts! (and (> (len title) u0) (> (len description) u0)) ERR-INVALID-PARAMETERS)
    (asserts! (is-valid-ip-type ip-type) ERR-INVALID-PARAMETERS)
    
    ;; Check if IP already exists with this ID or hash
    (asserts! (is-none (map-get? intellectual-properties { ip-id: ip-id })) ERR-ALREADY-EXISTS)
    (asserts! (is-none (map-get? ip-hash-registry { content-hash: content-hash })) ERR-ALREADY-EXISTS)
    
    ;; Process payment
    (try! (stx-transfer? IP-REGISTRATION-FEE tx-sender (as-contract tx-sender)))
    
    ;; Register IP
    (map-set intellectual-properties
      { ip-id: ip-id }
      {
        owner: tx-sender,
        title: title,
        description: description,
        ip-type: ip-type,
        hash: content-hash,
        registration-block: registration-block,
        expiry-block: expiry-block,
        status: "active",
        license-terms: license-terms
      }
    )
    
    ;; Register hash to prevent duplicates
    (map-set ip-hash-registry
      { content-hash: content-hash }
      { ip-id: ip-id, owner: tx-sender }
    )
    
    ;; Update contract state
    (var-set next-ip-id (+ ip-id u1))
    (var-set contract-balance (+ (var-get contract-balance) IP-REGISTRATION-FEE))
    
    (ok ip-id)
  )
)

;; Renew IP registration
(define-public (renew-ip (ip-id uint))
  (let (
    (ip-data (unwrap! (map-get? intellectual-properties { ip-id: ip-id }) ERR-NOT-FOUND))
    (new-expiry (+ (get expiry-block ip-data) IP-VALIDITY-PERIOD))
  )
    ;; Verify ownership
    (asserts! (is-ip-owner ip-id tx-sender) ERR-NOT-AUTHORIZED)
    
    ;; Process payment
    (try! (stx-transfer? IP-RENEWAL-FEE tx-sender (as-contract tx-sender)))
    
    ;; Update IP
    (map-set intellectual-properties
      { ip-id: ip-id }
      (merge ip-data { 
        expiry-block: new-expiry,
        status: "active"
      })
    )
    
    (var-set contract-balance (+ (var-get contract-balance) IP-RENEWAL-FEE))
    (ok true)
  )
)

;; Transfer IP ownership
(define-public (transfer-ip (ip-id uint) (new-owner principal))
  (let (
    (ip-data (unwrap! (map-get? intellectual-properties { ip-id: ip-id }) ERR-NOT-FOUND))
  )
    ;; Verify ownership and IP is active
    (asserts! (is-ip-owner ip-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-ip-active ip-id) ERR-EXPIRED)
    
    ;; Transfer ownership
    (map-set intellectual-properties
      { ip-id: ip-id }
      (merge ip-data { owner: new-owner })
    )
    
    (ok true)
  )
)

;; Grant license
(define-public (grant-license
  (ip-id uint)
  (licensee principal)
  (license-type (string-ascii 20))
  (duration uint)
  (royalty-rate uint)
  (terms (string-ascii 200))
)
  (let (
    (start-block block-height)
    (end-block (+ block-height duration))
  )
    ;; Verify ownership and IP is active
    (asserts! (is-ip-owner ip-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-ip-active ip-id) ERR-EXPIRED)
    (asserts! (<= royalty-rate u10000) ERR-INVALID-PARAMETERS) ;; Max 100%
    
    ;; Grant license
    (map-set ip-licenses
      { ip-id: ip-id, licensee: licensee }
      {
        licensor: tx-sender,
        license-type: license-type,
        start-block: start-block,
        end-block: end-block,
        royalty-rate: royalty-rate,
        terms: terms,
        active: true
      }
    )
    
    (ok true)
  )
)

;; Revoke license
(define-public (revoke-license (ip-id uint) (licensee principal))
  (let (
    (license-data (unwrap! (map-get? ip-licenses { ip-id: ip-id, licensee: licensee }) ERR-NOT-FOUND))
  )
    ;; Verify licensor
    (asserts! (is-eq (get licensor license-data) tx-sender) ERR-NOT-AUTHORIZED)
    
    ;; Revoke license
    (map-set ip-licenses
      { ip-id: ip-id, licensee: licensee }
      (merge license-data { active: false })
    )
    
    (ok true)
  )
)

;; File dispute
(define-public (file-dispute
  (ip-id uint)
  (dispute-type (string-ascii 30))
  (evidence-hash (buff 32))
)
  (let (
    (dispute-id (var-get next-dispute-id))
    (ip-data (unwrap! (map-get? intellectual-properties { ip-id: ip-id }) ERR-NOT-FOUND))
  )
    ;; Verify IP exists and challenger is not the owner
    (asserts! (not (is-ip-owner ip-id tx-sender)) ERR-NOT-AUTHORIZED)
    
    ;; File dispute
    (map-set ip-disputes
      { dispute-id: dispute-id }
      {
        ip-id: ip-id,
        challenger: tx-sender,
        owner: (get owner ip-data),
        dispute-type: dispute-type,
        evidence-hash: evidence-hash,
        status: "pending",
        filed-block: block-height,
        resolved-block: none
      }
    )
    
    (var-set next-dispute-id (+ dispute-id u1))
    (ok dispute-id)
  )
)

;; Resolve dispute (only contract owner can resolve)
(define-public (resolve-dispute (dispute-id uint) (resolution (string-ascii 20)))
  (let (
    (dispute-data (unwrap! (map-get? ip-disputes { dispute-id: dispute-id }) ERR-NOT-FOUND))
  )
    ;; Only contract owner can resolve disputes
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status dispute-data) "pending") ERR-INVALID-PARAMETERS)
    
    ;; Resolve dispute
    (map-set ip-disputes
      { dispute-id: dispute-id }
      (merge dispute-data { 
        status: resolution,
        resolved-block: (some block-height)
      })
    )
    
    ;; If dispute is upheld, revoke the IP
    (if (is-eq resolution "upheld")
      (map-set intellectual-properties
        { ip-id: (get ip-id dispute-data) }
        (merge (unwrap-panic (map-get? intellectual-properties { ip-id: (get ip-id dispute-data) }))
               { status: "revoked" })
      )
      true
    )
    
    (ok true)
  )
)

;; Read-only functions

;; Get IP details
(define-read-only (get-ip-details (ip-id uint))
  (map-get? intellectual-properties { ip-id: ip-id })
)

;; Get license details
(define-read-only (get-license-details (ip-id uint) (licensee principal))
  (map-get? ip-licenses { ip-id: ip-id, licensee: licensee })
)

;; Get dispute details
(define-read-only (get-dispute-details (dispute-id uint))
  (map-get? ip-disputes { dispute-id: dispute-id })
)

;; Check if user has valid license
(define-read-only (has-valid-license (ip-id uint) (user principal))
  (match (map-get? ip-licenses { ip-id: ip-id, licensee: user })
    license-data (and (get active license-data)
                     (>= block-height (get start-block license-data))
                     (<= block-height (get end-block license-data)))
    false
  )
)

;; Verify IP authenticity
(define-read-only (verify-ip-authenticity (ip-id uint) (content-hash (buff 32)))
  (match (map-get? intellectual-properties { ip-id: ip-id })
    ip-data (is-eq (get hash ip-data) content-hash)
    false
  )
)

;; Get contract stats
(define-read-only (get-contract-stats)
  {
    total-ips: (- (var-get next-ip-id) u1),
    total-disputes: (- (var-get next-dispute-id) u1),
    contract-balance: (var-get contract-balance)
  }
)

;; Get IP details by hash
(define-read-only (get-ip-by-hash (content-hash (buff 32)))
  (map-get? ip-hash-registry { content-hash: content-hash })
)

;; Check if hash is already registered
(define-read-only (is-hash-registered (content-hash (buff 32)))
  (is-some (map-get? ip-hash-registry { content-hash: content-hash }))
)

;; Administrative functions

;; Withdraw contract balance (only owner)
(define-public (withdraw-balance (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= amount (var-get contract-balance)) ERR-INSUFFICIENT-PAYMENT)
    
    (try! (as-contract (stx-transfer? amount tx-sender CONTRACT-OWNER)))
    (var-set contract-balance (- (var-get contract-balance) amount))
    (ok true)
  )
)

;; Emergency functions

;; Pause IP registration (only owner)
(define-public (emergency-pause)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    ;; Implementation would include a pause mechanism
    (ok true)
  )
)