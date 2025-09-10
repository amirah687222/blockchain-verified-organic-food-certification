;; farm-validator
;; Smart contract for managing farm registration, validation, and certification
;; in the organic food certification system

;; constants
;;
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-FARM-NOT-FOUND (err u101))
(define-constant ERR-FARM-EXISTS (err u102))
(define-constant ERR-VALIDATOR-NOT-FOUND (err u103))
(define-constant ERR-INVALID-STATUS (err u104))
(define-constant ERR-INVALID-SCORE (err u105))
(define-constant ERR-VALIDATION-EXISTS (err u106))

;; Farm status constants
(define-constant STATUS-PENDING u1)
(define-constant STATUS-VALIDATED u2)
(define-constant STATUS-CERTIFIED u3)
(define-constant STATUS-SUSPENDED u4)
(define-constant STATUS-REVOKED u5)

;; data vars
;;
(define-data-var farm-counter uint u0)
(define-data-var validator-counter uint u0)
(define-data-var validation-counter uint u0)

;; data maps
;;
(define-map farms
    { farm-id: uint }
    {
        owner: principal,
        farm-name: (string-ascii 100),
        location: (string-ascii 200),
        size-acres: uint,
        registration-date: uint,
        status: uint,
        certification-score: uint,
        validator-count: uint,
        last-inspection: (optional uint)
    }
)

(define-map validators
    { validator-id: uint }
    {
        validator-address: principal,
        validator-name: (string-ascii 100),
        certification-authority: (string-ascii 100),
        registration-date: uint,
        total-validations: uint,
        average-score: uint,
        is-active: bool
    }
)

(define-map farm-validations
    { farm-id: uint, validation-id: uint }
    {
        validator-id: uint,
        validation-date: uint,
        compliance-score: uint,
        soil-quality-score: uint,
        water-quality-score: uint,
        organic-practices-score: uint,
        documentation-score: uint,
        overall-score: uint,
        notes: (string-ascii 500),
        approved: bool
    }
)

(define-map farm-owners
    { owner: principal }
    { farm-ids: (list 10 uint) }
)

(define-map validator-assignments
    { validator-id: uint }
    { assigned-farms: (list 50 uint) }
)

;; public functions
;;
(define-public (register-farm 
    (farm-name (string-ascii 100))
    (location (string-ascii 200))
    (size-acres uint)
)
    (let
        (
            (new-farm-id (+ (var-get farm-counter) u1))
            (current-block-height block-height)
        )
        (asserts! (> (len farm-name) u0) ERR-INVALID-STATUS)
        (asserts! (> (len location) u0) ERR-INVALID-STATUS)
        (asserts! (> size-acres u0) ERR-INVALID-STATUS)
        
        (map-set farms
            { farm-id: new-farm-id }
            {
                owner: tx-sender,
                farm-name: farm-name,
                location: location,
                size-acres: size-acres,
                registration-date: current-block-height,
                status: STATUS-PENDING,
                certification-score: u0,
                validator-count: u0,
                last-inspection: none
            }
        )
        
        (let ((current-farms (default-to (list) (get farm-ids (map-get? farm-owners { owner: tx-sender })))))
            (map-set farm-owners
                { owner: tx-sender }
                { farm-ids: (unwrap! (as-max-len? (append current-farms new-farm-id) u10) ERR-INVALID-STATUS) }
            )
        )
        
        (var-set farm-counter new-farm-id)
        (ok new-farm-id)
    )
)

(define-public (register-validator
    (validator-name (string-ascii 100))
    (certification-authority (string-ascii 100))
)
    (let
        (
            (new-validator-id (+ (var-get validator-counter) u1))
            (current-block-height block-height)
        )
        (asserts! (> (len validator-name) u0) ERR-INVALID-STATUS)
        (asserts! (> (len certification-authority) u0) ERR-INVALID-STATUS)
        
        (map-set validators
            { validator-id: new-validator-id }
            {
                validator-address: tx-sender,
                validator-name: validator-name,
                certification-authority: certification-authority,
                registration-date: current-block-height,
                total-validations: u0,
                average-score: u0,
                is-active: true
            }
        )
        
        (var-set validator-counter new-validator-id)
        (ok new-validator-id)
    )
)

(define-public (submit-farm-validation
    (farm-id uint)
    (validator-id uint)
    (compliance-score uint)
    (soil-quality-score uint)
    (water-quality-score uint)
    (organic-practices-score uint)
    (documentation-score uint)
    (notes (string-ascii 500))
)
    (let
        (
            (farm-data (unwrap! (map-get? farms { farm-id: farm-id }) ERR-FARM-NOT-FOUND))
            (validator-data (unwrap! (map-get? validators { validator-id: validator-id }) ERR-VALIDATOR-NOT-FOUND))
            (new-validation-id (+ (var-get validation-counter) u1))
            (overall-score (/ (+ compliance-score soil-quality-score water-quality-score organic-practices-score documentation-score) u5))
            (approved (>= overall-score u70))
        )
        (asserts! (is-eq tx-sender (get validator-address validator-data)) ERR-NOT-AUTHORIZED)
        (asserts! (get is-active validator-data) ERR-VALIDATOR-NOT-FOUND)
        (asserts! (<= compliance-score u100) ERR-INVALID-SCORE)
        (asserts! (<= soil-quality-score u100) ERR-INVALID-SCORE)
        (asserts! (<= water-quality-score u100) ERR-INVALID-SCORE)
        (asserts! (<= organic-practices-score u100) ERR-INVALID-SCORE)
        (asserts! (<= documentation-score u100) ERR-INVALID-SCORE)
        
        (map-set farm-validations
            { farm-id: farm-id, validation-id: new-validation-id }
            {
                validator-id: validator-id,
                validation-date: block-height,
                compliance-score: compliance-score,
                soil-quality-score: soil-quality-score,
                water-quality-score: water-quality-score,
                organic-practices-score: organic-practices-score,
                documentation-score: documentation-score,
                overall-score: overall-score,
                notes: notes,
                approved: approved
            }
        )
        
        ;; Update farm status and validator count
        (map-set farms
            { farm-id: farm-id }
            (merge farm-data {
                status: (if approved STATUS-VALIDATED STATUS-PENDING),
                certification-score: overall-score,
                validator-count: (+ (get validator-count farm-data) u1),
                last-inspection: (some block-height)
            })
        )
        
        ;; Update validator stats
        (map-set validators
            { validator-id: validator-id }
            (merge validator-data {
                total-validations: (+ (get total-validations validator-data) u1),
                average-score: (/ (+ (* (get average-score validator-data) (get total-validations validator-data)) overall-score)
                                  (+ (get total-validations validator-data) u1))
            })
        )
        
        (var-set validation-counter new-validation-id)
        (ok new-validation-id)
    )
)

(define-public (update-farm-status
    (farm-id uint)
    (new-status uint)
)
    (let
        (
            (farm-data (unwrap! (map-get? farms { farm-id: farm-id }) ERR-FARM-NOT-FOUND))
        )
        (asserts! (or (is-eq tx-sender CONTRACT-OWNER) (is-eq tx-sender (get owner farm-data))) ERR-NOT-AUTHORIZED)
        (asserts! (and (>= new-status STATUS-PENDING) (<= new-status STATUS-REVOKED)) ERR-INVALID-STATUS)
        
        (map-set farms
            { farm-id: farm-id }
            (merge farm-data { status: new-status })
        )
        
        (ok true)
    )
)

(define-public (deactivate-validator (validator-id uint))
    (let
        (
            (validator-data (unwrap! (map-get? validators { validator-id: validator-id }) ERR-VALIDATOR-NOT-FOUND))
        )
        (asserts! (or (is-eq tx-sender CONTRACT-OWNER) (is-eq tx-sender (get validator-address validator-data))) ERR-NOT-AUTHORIZED)
        
        (map-set validators
            { validator-id: validator-id }
            (merge validator-data { is-active: false })
        )
        
        (ok true)
    )
)

;; read only functions
;;
(define-read-only (get-farm-info (farm-id uint))
    (map-get? farms { farm-id: farm-id })
)

(define-read-only (get-validator-info (validator-id uint))
    (map-get? validators { validator-id: validator-id })
)

(define-read-only (get-farm-validation (farm-id uint) (validation-id uint))
    (map-get? farm-validations { farm-id: farm-id, validation-id: validation-id })
)

(define-read-only (get-farms-by-owner (owner principal))
    (get farm-ids (map-get? farm-owners { owner: owner }))
)

(define-read-only (get-farm-count)
    (var-get farm-counter)
)

(define-read-only (get-validator-count)
    (var-get validator-counter)
)

(define-read-only (is-farm-certified (farm-id uint))
    (match (map-get? farms { farm-id: farm-id })
        farm-data (>= (get status farm-data) STATUS-VALIDATED)
        false
    )
)

;; private functions
;;
(define-private (calculate-weighted-score (scores (list 5 uint)))
    (fold + scores u0)
)
