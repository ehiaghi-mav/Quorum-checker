;; Quorum Checker Smart Contract
;; A complete implementation for governance voting with quorum verification

;; ============================================================================
;; ERROR CODES
;; ============================================================================

(define-constant ERR-NOT-OWNER (err u100))
(define-constant ERR-INVALID-QUORUM (err u101))
(define-constant ERR-ALREADY-INITIALIZED (err u102))
(define-constant ERR-QUORUM-NOT-MET (err u103))
(define-constant ERR-NOT-MEMBER (err u104))
(define-constant ERR-ALREADY-VOTED (err u105))
(define-constant ERR-VOTE-CLOSED (err u106))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u107))

;; ============================================================================
;; DATA STRUCTURES & VARIABLES
;; ============================================================================

;; Contract owner
(define-data-var contract-owner principal tx-sender)

;; Members list (maximum 100 members for practical governance)
(define-data-var members (list 100 principal) (list))

;; Quorum threshold (percentage, e.g., 51 = 51%)
(define-data-var quorum-threshold uint u51)

;; Total members count for efficiency
(define-data-var total-members uint u0)

;; Proposal counter for unique IDs
(define-data-var proposal-counter uint u0)

;; Map to store proposals: proposal-id -> proposal data
(define-map proposals uint {
  id: uint,
  title: (string-utf8 256),
  description: (string-utf8 500),
  creator: principal,
  votes-for: uint,
  votes-against: uint,
  total-votes: uint,
  status: (string-utf8 20),
  created-block: uint,
  deadline-block: uint
})

;; Map to track individual votes: (proposal-id, voter) -> vote (true = yes, false = no)
(define-map voter-votes { proposal-id: uint, voter: principal } bool)

;; Map to track who has voted on a proposal
(define-map has-voted { proposal-id: uint, voter: principal } bool)

;; ============================================================================
;; INITIALIZATION FUNCTIONS
;; ============================================================================

;; Initialize contract with members and quorum threshold
;; Only callable once by the contract owner
(define-public (initialize (new-members (list 100 principal)) (threshold uint))
  (begin
    ;; Verify caller is contract owner
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-OWNER)
    
    ;; Ensure not already initialized
    (asserts! (is-eq (var-get total-members) u0) ERR-ALREADY-INITIALIZED)
    
    ;; Validate quorum threshold is between 1-100
    (asserts! (and (> threshold u0) (<= threshold u100)) ERR-INVALID-QUORUM)
    
    ;; Validate at least one member
    (asserts! (> (len new-members) u0) ERR-INVALID-QUORUM)
    
    ;; Set members and threshold
    (var-set members new-members)
    (var-set total-members (len new-members))
    (var-set quorum-threshold threshold)
    
    (ok true)
  )
)

;; ============================================================================
;; PROPOSAL MANAGEMENT FUNCTIONS
;; =========================================================================

;; Create a new proposal
(define-public (create-proposal (title (string-utf8 256)) (description (string-utf8 500)) (voting-period uint))
  (let 
    (
      (proposal-id (+ (var-get proposal-counter) u1))
      (current-block stacks-block-height)
      (deadline (+ current-block voting-period))
    )
    
    ;; Verify caller is a member
    (asserts! (is-some (index-of (var-get members) tx-sender)) ERR-NOT-MEMBER)
    
    ;; Create the proposal
    (map-set proposals proposal-id {
      id: proposal-id,
      title: title,
      description: description,
      creator: tx-sender,
      votes-for: u0,
      votes-against: u0,
      total-votes: u0,
      status: u"active",
      created-block: current-block,
      deadline-block: deadline
    })
    
    ;; Increment proposal counter
    (var-set proposal-counter proposal-id)
    
    (ok proposal-id)
  )
)

;; ============================================================================
;; VOTING FUNCTIONS
;; ============================================================================

;; Cast a vote on a proposal
(define-public (vote (proposal-id uint) (vote-for bool))
  (let
    (
      (proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND))
      (current-block stacks-block-height)
      (vote-key { proposal-id: proposal-id, voter: tx-sender })
      (votes-for (get votes-for proposal))
      (votes-against (get votes-against proposal))
      (total-votes (get total-votes proposal))
    )
    
    ;; Verify caller is a member
    (asserts! (is-some (index-of (var-get members) tx-sender)) ERR-NOT-MEMBER)
    
    ;; Verify proposal is still active
    (asserts! (< current-block (get deadline-block proposal)) ERR-VOTE-CLOSED)
    
    ;; Verify member has not already voted
    (asserts! (is-none (map-get? has-voted vote-key)) ERR-ALREADY-VOTED)
    
    ;; Record the vote
    (map-set voter-votes vote-key vote-for)
    (map-set has-voted vote-key true)
    
    ;; Update proposal vote counts
    (if vote-for
      (map-set proposals proposal-id (merge proposal {
        votes-for: (+ votes-for u1),
        total-votes: (+ total-votes u1)
      }))
      (map-set proposals proposal-id (merge proposal {
        votes-against: (+ votes-against u1),
        total-votes: (+ total-votes u1)
      }))
    )
    
    (ok true)
  )
)

;; ============================================================================
;; QUORUM VERIFICATION FUNCTIONS
;; ============================================================================

;; Check if quorum is met for a proposal
;; Returns true if voting participation meets the quorum threshold
(define-read-only (is-quorum-met (proposal-id uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals proposal-id) false))
      (total-votes (get total-votes proposal))
      (members-count (var-get total-members))
      ;; Calculate required votes: (members-count * quorum-threshold) / 100
      (votes-required (/ (* members-count (var-get quorum-threshold)) u100))
    )
    ;; Quorum is met if total votes >= required votes
    (>= total-votes votes-required)
  )
)

;; Get quorum requirement details
(define-read-only (get-quorum-info)
  {
    total-members: (var-get total-members),
    quorum-threshold: (var-get quorum-threshold),
    required-votes: (/ (* (var-get total-members) (var-get quorum-threshold)) u100)
  }
)

;; Calculate votes needed to reach quorum for a specific proposal
(define-read-only (votes-needed-for-quorum (proposal-id uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals proposal-id) u0))
      (total-votes (get total-votes proposal))
      (votes-required (/ (* (var-get total-members) (var-get quorum-threshold)) u100))
    )
    ;; Return 0 if quorum already met, otherwise return votes still needed
    (if (>= total-votes votes-required)
      u0
      (- votes-required total-votes)
    )
  )
)

;; ============================================================================
;; PROPOSAL QUERY FUNCTIONS
;; ============================================================================

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id)
)

;; Get total proposals created
(define-read-only (get-total-proposals)
  (var-get proposal-counter)
)

;; Check if a specific member has voted on a proposal
(define-read-only (has-member-voted (proposal-id uint) (member principal))
  (is-some (map-get? has-voted { proposal-id: proposal-id, voter: member }))
)

;; Get voting participation percentage for a proposal
(define-read-only (get-participation-percentage (proposal-id uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals proposal-id) u0))
      (total-votes (get total-votes proposal))
      (members-count (var-get total-members))
    )
    ;; Return percentage: (total-votes * 100) / members-count
    (/ (* total-votes u100) members-count)
  )
)

;; ============================================================================
;; MEMBER MANAGEMENT FUNCTIONS
;; ============================================================================

;; Get list of all members
(define-read-only (get-members)
  (var-get members)
)

;; Check if a principal is a member
(define-read-only (is-member (principal-to-check principal))
  (is-some (index-of (var-get members) principal-to-check))
)

;; Get total number of members
(define-read-only (get-member-count)
  (var-get total-members)
)

;; ============================================================================
;; STATUS & UTILITY FUNCTIONS
;; ============================================================================

;; Close a proposal voting period (set status to closed)
(define-public (close-proposal (proposal-id uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND))
    )
    ;; Verify caller is proposal creator or contract owner
    (asserts! 
      (or 
        (is-eq tx-sender (get creator proposal))
        (is-eq tx-sender (var-get contract-owner))
      )
      ERR-NOT-OWNER
    )
    
    ;; Update proposal status
    (map-set proposals proposal-id (merge proposal { status: u"closed" }))
    
    (ok true)
  )
)

;; Get proposal status and quorum information
(define-read-only (get-proposal-status (proposal-id uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals proposal-id) {
        status: u"not-found",
        quorum-met: false,
        participation-percentage: u0
      }))
    )
    {
      status: (get status proposal),
      quorum-met: (is-quorum-met proposal-id),
      participation-percentage: (get-participation-percentage proposal-id),
      votes-for: (get votes-for proposal),
      votes-against: (get votes-against proposal),
      total-votes: (get total-votes proposal)
    }
  )
)
