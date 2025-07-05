;; Syndicate Contract
;; Enables fractional ownership of thoroughbred horses with automated prize distribution

;; Constants
(define-constant STABLE_MASTER tx-sender)
(define-constant ERR_UNAUTHORIZED_OWNER (err u800))
(define-constant ERR_INSUFFICIENT_SHARES (err u801))
(define-constant ERR_HORSE_NOT_FOUND (err u802))
(define-constant ERR_INVALID_AMOUNT (err u803))
(define-constant ERR_RACE_NOT_FOUND (err u804))
(define-constant ERR_ALREADY_VOTED (err u805))

;; Data Variables
(define-data-var next-horse-id uint u1)
(define-data-var next-race-id uint u1)

;; Horse Structure
(define-map thoroughbreds 
  { horse-id: uint }
  {
    horse-name: (string-ascii 100),
    total-shares: uint,
    share-cost: uint,
    race-earnings: uint,
    head-trainer: principal,
    is-racing: bool
  }
)

;; Share Ownership
(define-map owner-shares
  { horse-id: uint, owner: principal }
  { shares: uint }
)

;; Race Decisions
(define-map race-decisions
  { race-id: uint }
  {
    horse-id: uint,
    race-name: (string-ascii 100),
    strategy: (string-ascii 500),
    proposer: principal,
    yes-votes: uint,
    no-votes: uint,
    decision-deadline: uint,
    finalized: bool
  }
)

;; Voting Records
(define-map race-votes
  { race-id: uint, voter: principal }
  { voted: bool, agrees: bool }
)

;; Prize Distribution Tracking
(define-map prize-claims
  { horse-id: uint, owner: principal, season: uint }
  { claimed: bool }
)

;; Horse Registration
(define-public (register-horse 
  (horse-name (string-ascii 100))
  (total-shares uint)
  (share-cost uint)
  (race-earnings uint)
  (head-trainer principal))
  (let ((horse-id (var-get next-horse-id)))
    (asserts! (is-eq tx-sender STABLE_MASTER) ERR_UNAUTHORIZED_OWNER)
    (asserts! (> total-shares u0) ERR_INVALID_AMOUNT)
    (asserts! (> share-cost u0) ERR_INVALID_AMOUNT)
    
    (map-set thoroughbreds
      { horse-id: horse-id }
      {
        horse-name: horse-name,
        total-shares: total-shares,
        share-cost: share-cost,
        race-earnings: race-earnings,
        head-trainer: head-trainer,
        is-racing: true
      }
    )
    
    (var-set next-horse-id (+ horse-id u1))
    (ok horse-id)
  )
)

;; Purchase Horse Shares
(define-public (buy-shares (horse-id uint) (share-amount uint))
  (let (
    (horse (unwrap! (map-get? thoroughbreds { horse-id: horse-id }) ERR_HORSE_NOT_FOUND))
    (total-cost (* share-amount (get share-cost horse)))
    (current-shares (default-to u0 (get shares (map-get? owner-shares { horse-id: horse-id, owner: tx-sender }))))
  )
    (asserts! (get is-racing horse) ERR_HORSE_NOT_FOUND)
    (asserts! (> share-amount u0) ERR_INVALID_AMOUNT)
    
    (map-set owner-shares
      { horse-id: horse-id, owner: tx-sender }
      { shares: (+ current-shares share-amount) }
    )
    
    (ok share-amount)
  )
)

;; Distribute Race Winnings
(define-public (distribute-winnings (horse-id uint) (season uint))
  (let (
    (horse (unwrap! (map-get? thoroughbreds { horse-id: horse-id }) ERR_HORSE_NOT_FOUND))
    (race-earnings (get race-earnings horse))
    (total-shares (get total-shares horse))
  )
    (asserts! (is-eq tx-sender (get head-trainer horse)) ERR_UNAUTHORIZED_OWNER)
    (asserts! (get is-racing horse) ERR_HORSE_NOT_FOUND)
    
    (ok true)
  )
)

;; Claim Prize Share
(define-public (claim-winnings (horse-id uint) (season uint))
  (let (
    (horse (unwrap! (map-get? thoroughbreds { horse-id: horse-id }) ERR_HORSE_NOT_FOUND))
    (share-balance (default-to u0 (get shares (map-get? owner-shares { horse-id: horse-id, owner: tx-sender }))))
    (already-claimed (default-to false (get claimed (map-get? prize-claims { horse-id: horse-id, owner: tx-sender, season: season }))))
    (race-earnings (get race-earnings horse))
    (total-shares (get total-shares horse))
    (winning-share (/ (* race-earnings share-balance) total-shares))
  )
    (asserts! (> share-balance u0) ERR_INSUFFICIENT_SHARES)
    (asserts! (not already-claimed) ERR_UNAUTHORIZED_OWNER)
    
    (map-set prize-claims
      { horse-id: horse-id, owner: tx-sender, season: season }
      { claimed: true }
    )
    
    (ok winning-share)
  )
)

;; Create Race Decision
(define-public (create-race-decision 
  (horse-id uint)
  (race-name (string-ascii 100))
  (strategy (string-ascii 500))
  (voting-period uint))
  (let (
    (race-id (var-get next-race-id))
    (share-balance (default-to u0 (get shares (map-get? owner-shares { horse-id: horse-id, owner: tx-sender }))))
    (decision-deadline (+ block-height voting-period))
  )
    (asserts! (> share-balance u0) ERR_UNAUTHORIZED_OWNER)
    
    (map-set race-decisions
      { race-id: race-id }
      {
        horse-id: horse-id,
        race-name: race-name,
        strategy: strategy,
        proposer: tx-sender,
        yes-votes: u0,
        no-votes: u0,
        decision-deadline: decision-deadline,
        finalized: false
      }
    )
    
    (var-set next-race-id (+ race-id u1))
    (ok race-id)
  )
)

;; Vote on Race Decision
(define-public (vote-race (race-id uint) (agrees bool))
  (let (
    (race (unwrap! (map-get? race-decisions { race-id: race-id }) ERR_RACE_NOT_FOUND))
    (horse-id (get horse-id race))
    (share-balance (default-to u0 (get shares (map-get? owner-shares { horse-id: horse-id, owner: tx-sender }))))
    (already-voted (default-to false (get voted (map-get? race-votes { race-id: race-id, voter: tx-sender }))))
    (current-yes (get yes-votes race))
    (current-no (get no-votes race))
  )
    (asserts! (> share-balance u0) ERR_UNAUTHORIZED_OWNER)
    (asserts! (<= block-height (get decision-deadline race)) ERR_UNAUTHORIZED_OWNER)
    (asserts! (not already-voted) ERR_ALREADY_VOTED)
    
    (map-set race-votes
      { race-id: race-id, voter: tx-sender }
      { voted: true, agrees: agrees }
    )
    
    (if agrees
      (map-set race-decisions
        { race-id: race-id }
        (merge race { yes-votes: (+ current-yes share-balance) })
      )
      (map-set race-decisions
        { race-id: race-id }
        (merge race { no-votes: (+ current-no share-balance) })
      )
    )
    
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-horse (horse-id uint))
  (map-get? thoroughbreds { horse-id: horse-id })
)

(define-read-only (get-share-balance (horse-id uint) (owner principal))
  (default-to u0 (get shares (map-get? owner-shares { horse-id: horse-id, owner: owner })))
)

(define-read-only (get-race-decision (race-id uint))
  (map-get? race-decisions { race-id: race-id })
)

(define-read-only (calculate-winning-share (horse-id uint) (owner principal))
  (let (
    (horse (unwrap! (map-get? thoroughbreds { horse-id: horse-id }) ERR_HORSE_NOT_FOUND))
    (share-balance (default-to u0 (get shares (map-get? owner-shares { horse-id: horse-id, owner: owner }))))
    (race-earnings (get race-earnings horse))
    (total-shares (get total-shares horse))
  )
    (if (> share-balance u0)
      (ok (/ (* race-earnings share-balance) total-shares))
      (ok u0)
    )
  )
)