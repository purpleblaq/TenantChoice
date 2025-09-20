;; title: TenantChoice
;; version: 1.0.0
;; summary: A collaborative voting system for building management and resident community policies
;; description: Enables tenants to register, create proposals, and vote on building management decisions

;; traits
;;

;; token definitions
;;

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-tenant (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-proposal-not-found (err u103))
(define-constant err-already-voted (err u104))
(define-constant err-voting-closed (err u105))
(define-constant err-invalid-proposal (err u106))
(define-constant err-tenant-not-found (err u107))

;; data vars
(define-data-var next-proposal-id uint u1)
(define-data-var total-tenants uint u0)

;; data maps
;; Tenant registry - maps principal to tenant info
(define-map tenants principal {
    apartment-number: uint,
    is-active: bool,
    registration-block: uint
})

;; Proposal data structure
(define-map proposals uint {
    title: (string-ascii 100),
    description: (string-ascii 500),
    creator: principal,
    created-at: uint,
    voting-end-block: uint,
    yes-votes: uint,
    no-votes: uint,
    is-active: bool
})

;; Track individual votes - maps (proposal-id, voter) to vote choice
(define-map votes {proposal-id: uint, voter: principal} bool)

;; public functions

;; Register a new tenant
(define-public (register-tenant (apartment-number uint))
    (let ((tenant tx-sender))
        (asserts! (is-none (map-get? tenants tenant)) err-already-registered)
        (map-set tenants tenant {
            apartment-number: apartment-number,
            is-active: true,
            registration-block: block-height
        })
        (var-set total-tenants (+ (var-get total-tenants) u1))
        (ok true)
    )
)

;; Deactivate a tenant (only contract owner can do this)
(define-public (deactivate-tenant (tenant principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-some (map-get? tenants tenant)) err-tenant-not-found)
        (map-set tenants tenant (merge (unwrap-panic (map-get? tenants tenant)) {is-active: false}))
        (var-set total-tenants (- (var-get total-tenants) u1))
        (ok true)
    )
)

;; Create a new proposal
(define-public (create-proposal (title (string-ascii 100)) (description (string-ascii 500)) (voting-duration uint))
    (let ((proposal-id (var-get next-proposal-id))
          (tenant-info (map-get? tenants tx-sender)))
        (asserts! (is-some tenant-info) err-not-tenant)
        (asserts! (get is-active (unwrap-panic tenant-info)) err-not-tenant)
        (asserts! (> (len title) u0) err-invalid-proposal)
        (asserts! (> voting-duration u0) err-invalid-proposal)

        (map-set proposals proposal-id {
            title: title,
            description: description,
            creator: tx-sender,
            created-at: block-height,
            voting-end-block: (+ block-height voting-duration),
            yes-votes: u0,
            no-votes: u0,
            is-active: true
        })

        (var-set next-proposal-id (+ proposal-id u1))
        (ok proposal-id)
    )
)

;; Vote on a proposal
(define-public (vote (proposal-id uint) (vote-choice bool))
    (let ((proposal (map-get? proposals proposal-id))
          (tenant-info (map-get? tenants tx-sender))
          (vote-key {proposal-id: proposal-id, voter: tx-sender}))

        ;; Validate voter is an active tenant
        (asserts! (is-some tenant-info) err-not-tenant)
        (asserts! (get is-active (unwrap-panic tenant-info)) err-not-tenant)

        ;; Validate proposal exists and is active
        (asserts! (is-some proposal) err-proposal-not-found)
        (let ((proposal-data (unwrap-panic proposal)))
            (asserts! (get is-active proposal-data) err-proposal-not-found)
            (asserts! (<= block-height (get voting-end-block proposal-data)) err-voting-closed)

            ;; Check if already voted
            (asserts! (is-none (map-get? votes vote-key)) err-already-voted)

            ;; Record the vote
            (map-set votes vote-key vote-choice)

            ;; Update vote counts
            (if vote-choice
                (map-set proposals proposal-id
                    (merge proposal-data {yes-votes: (+ (get yes-votes proposal-data) u1)}))
                (map-set proposals proposal-id
                    (merge proposal-data {no-votes: (+ (get no-votes proposal-data) u1)}))
            )

            (ok true)
        )
    )
)

;; Close voting on a proposal (can be called by anyone after voting period ends)
(define-public (close-proposal (proposal-id uint))
    (let ((proposal (map-get? proposals proposal-id)))
        (asserts! (is-some proposal) err-proposal-not-found)
        (let ((proposal-data (unwrap-panic proposal)))
            (asserts! (get is-active proposal-data) err-proposal-not-found)
            (asserts! (> block-height (get voting-end-block proposal-data)) err-voting-closed)

            (map-set proposals proposal-id (merge proposal-data {is-active: false}))
            (ok true)
        )
    )
)

;; read only functions

;; Get tenant information
(define-read-only (get-tenant (tenant principal))
    (map-get? tenants tenant)
)

;; Get proposal information
(define-read-only (get-proposal (proposal-id uint))
    (map-get? proposals proposal-id)
)

;; Get vote for a specific voter on a specific proposal
(define-read-only (get-vote (proposal-id uint) (voter principal))
    (map-get? votes {proposal-id: proposal-id, voter: voter})
)

;; Check if a proposal has passed (simple majority)
(define-read-only (has-proposal-passed (proposal-id uint))
    (let ((proposal (map-get? proposals proposal-id)))
        (if (is-some proposal)
            (let ((proposal-data (unwrap-panic proposal)))
                (> (get yes-votes proposal-data) (get no-votes proposal-data))
            )
            false
        )
    )
)

;; Get total number of tenants
(define-read-only (get-total-tenants)
    (var-get total-tenants)
)

;; Get next proposal ID
(define-read-only (get-next-proposal-id)
    (var-get next-proposal-id)
)

;; Check if voting is still open for a proposal
(define-read-only (is-voting-open (proposal-id uint))
    (let ((proposal (map-get? proposals proposal-id)))
        (if (is-some proposal)
            (let ((proposal-data (unwrap-panic proposal)))
                (and
                    (get is-active proposal-data)
                    (<= block-height (get voting-end-block proposal-data))
                )
            )
            false
        )
    )
)

;; Get vote statistics for a proposal
(define-read-only (get-vote-stats (proposal-id uint))
    (let ((proposal (map-get? proposals proposal-id)))
        (if (is-some proposal)
            (let ((proposal-data (unwrap-panic proposal)))
                (ok {
                    yes-votes: (get yes-votes proposal-data),
                    no-votes: (get no-votes proposal-data),
                    total-votes: (+ (get yes-votes proposal-data) (get no-votes proposal-data))
                })
            )
            err-proposal-not-found
        )
    )
)

;; private functions
;;