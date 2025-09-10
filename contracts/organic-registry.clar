;; organic-registry
;; Smart contract for registering, certifying, and tracking organic products
;; in the blockchain-verified organic food certification system

;; constants
;;
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-PRODUCT-NOT-FOUND (err u201))
(define-constant ERR-PRODUCT-EXISTS (err u202))
(define-constant ERR-AUTHORITY-NOT-FOUND (err u203))
(define-constant ERR-INVALID-STATUS (err u204))
(define-constant ERR-INVALID-CERTIFICATION (err u205))
(define-constant ERR-SUPPLY-CHAIN-ERROR (err u206))
(define-constant ERR-EXPIRED-CERTIFICATION (err u207))

;; Product status constants
(define-constant PRODUCT-REGISTERED u1)
(define-constant PRODUCT-CERTIFIED u2)
(define-constant PRODUCT-IN-TRANSIT u3)
(define-constant PRODUCT-DELIVERED u4)
(define-constant PRODUCT-RECALLED u5)

;; Certification standards
(define-constant USDA-ORGANIC u1)
(define-constant EU-ORGANIC u2)
(define-constant JAS-ORGANIC u3)
(define-constant BIODYNAMIC u4)
(define-constant RAINFOREST-ALLIANCE u5)

;; data vars
;;
(define-data-var product-counter uint u0)
(define-data-var authority-counter uint u0)
(define-data-var certification-counter uint u0)
(define-data-var tracking-counter uint u0)

;; data maps
;;
(define-map products
    { product-id: uint }
    {
        farm-id: uint,
        producer: principal,
        product-name: (string-ascii 100),
        product-type: (string-ascii 50),
        batch-number: (string-ascii 50),
        production-date: uint,
        expiry-date: uint,
        quantity: uint,
        unit: (string-ascii 20),
        status: uint,
        current-location: (string-ascii 200),
        certifications: (list 5 uint),
        supply-chain-verified: bool
    }
)

(define-map certification-authorities
    { authority-id: uint }
    {
        authority-address: principal,
        authority-name: (string-ascii 100),
        accreditation-body: (string-ascii 100),
        standards-supported: (list 10 uint),
        registration-date: uint,
        total-certifications: uint,
        is-active: bool,
        reputation-score: uint
    }
)

(define-map product-certifications
    { product-id: uint, certification-id: uint }
    {
        authority-id: uint,
        standard-type: uint,
        certification-date: uint,
        expiry-date: uint,
        certificate-hash: (string-ascii 64),
        verification-status: bool,
        audit-notes: (string-ascii 500)
    }
)

(define-map supply-chain-tracking
    { product-id: uint, tracking-id: uint }
    {
        timestamp: uint,
        location: (string-ascii 200),
        handler: principal,
        activity: (string-ascii 100),
        temperature: (optional int),
        humidity: (optional uint),
        quality-notes: (string-ascii 300),
        verified: bool
    }
)

(define-map producer-products
    { producer: principal }
    { product-ids: (list 50 uint) }
)

(define-map authority-certifications
    { authority-id: uint }
    { certification-ids: (list 100 uint) }
)

;; public functions
;;
(define-public (register-product
    (farm-id uint)
    (product-name (string-ascii 100))
    (product-type (string-ascii 50))
    (batch-number (string-ascii 50))
    (production-date uint)
    (expiry-date uint)
    (quantity uint)
    (unit (string-ascii 20))
    (initial-location (string-ascii 200))
)
    (let
        (
            (new-product-id (+ (var-get product-counter) u1))
        )
        (asserts! (> (len product-name) u0) ERR-INVALID-STATUS)
        (asserts! (> (len product-type) u0) ERR-INVALID-STATUS)
        (asserts! (> (len batch-number) u0) ERR-INVALID-STATUS)
        (asserts! (> production-date u0) ERR-INVALID-STATUS)
        (asserts! (> expiry-date production-date) ERR-INVALID-STATUS)
        (asserts! (> quantity u0) ERR-INVALID-STATUS)
        
        (map-set products
            { product-id: new-product-id }
            {
                farm-id: farm-id,
                producer: tx-sender,
                product-name: product-name,
                product-type: product-type,
                batch-number: batch-number,
                production-date: production-date,
                expiry-date: expiry-date,
                quantity: quantity,
                unit: unit,
                status: PRODUCT-REGISTERED,
                current-location: initial-location,
                certifications: (list),
                supply-chain-verified: false
            }
        )
        
        (let ((current-products (default-to (list) (get product-ids (map-get? producer-products { producer: tx-sender })))))
            (map-set producer-products
                { producer: tx-sender }
                { product-ids: (unwrap! (as-max-len? (append current-products new-product-id) u50) ERR-SUPPLY-CHAIN-ERROR) }
            )
        )
        
        (var-set product-counter new-product-id)
        (ok new-product-id)
    )
)

(define-public (register-certification-authority
    (authority-name (string-ascii 100))
    (accreditation-body (string-ascii 100))
    (standards-supported (list 10 uint))
)
    (let
        (
            (new-authority-id (+ (var-get authority-counter) u1))
        )
        (asserts! (> (len authority-name) u0) ERR-INVALID-STATUS)
        (asserts! (> (len accreditation-body) u0) ERR-INVALID-STATUS)
        (asserts! (> (len standards-supported) u0) ERR-INVALID-STATUS)
        
        (map-set certification-authorities
            { authority-id: new-authority-id }
            {
                authority-address: tx-sender,
                authority-name: authority-name,
                accreditation-body: accreditation-body,
                standards-supported: standards-supported,
                registration-date: block-height,
                total-certifications: u0,
                is-active: true,
                reputation-score: u100
            }
        )
        
        (var-set authority-counter new-authority-id)
        (ok new-authority-id)
    )
)

(define-public (certify-product
    (product-id uint)
    (authority-id uint)
    (standard-type uint)
    (expiry-date uint)
    (certificate-hash (string-ascii 64))
    (audit-notes (string-ascii 500))
)
    (let
        (
            (product-data (unwrap! (map-get? products { product-id: product-id }) ERR-PRODUCT-NOT-FOUND))
            (authority-data (unwrap! (map-get? certification-authorities { authority-id: authority-id }) ERR-AUTHORITY-NOT-FOUND))
            (new-cert-id (+ (var-get certification-counter) u1))
        )
        (asserts! (is-eq tx-sender (get authority-address authority-data)) ERR-NOT-AUTHORIZED)
        (asserts! (get is-active authority-data) ERR-AUTHORITY-NOT-FOUND)
        (asserts! (is-some (index-of (get standards-supported authority-data) standard-type)) ERR-INVALID-CERTIFICATION)
        (asserts! (> expiry-date block-height) ERR-EXPIRED-CERTIFICATION)
        (asserts! (> (len certificate-hash) u0) ERR-INVALID-CERTIFICATION)
        
        (map-set product-certifications
            { product-id: product-id, certification-id: new-cert-id }
            {
                authority-id: authority-id,
                standard-type: standard-type,
                certification-date: block-height,
                expiry-date: expiry-date,
                certificate-hash: certificate-hash,
                verification-status: true,
                audit-notes: audit-notes
            }
        )
        
        ;; Update product with new certification
        (let ((current-certs (get certifications product-data)))
            (map-set products
                { product-id: product-id }
                (merge product-data {
                    status: PRODUCT-CERTIFIED,
                    certifications: (unwrap! (as-max-len? (append current-certs new-cert-id) u5) ERR-INVALID-CERTIFICATION)
                })
            )
        )
        
        ;; Update authority stats
        (map-set certification-authorities
            { authority-id: authority-id }
            (merge authority-data {
                total-certifications: (+ (get total-certifications authority-data) u1)
            })
        )
        
        (var-set certification-counter new-cert-id)
        (ok new-cert-id)
    )
)

(define-public (track-product-movement
    (product-id uint)
    (new-location (string-ascii 200))
    (activity (string-ascii 100))
    (temperature (optional int))
    (humidity (optional uint))
    (quality-notes (string-ascii 300))
)
    (let
        (
            (product-data (unwrap! (map-get? products { product-id: product-id }) ERR-PRODUCT-NOT-FOUND))
            (new-tracking-id (+ (var-get tracking-counter) u1))
        )
        (asserts! (> (len new-location) u0) ERR-SUPPLY-CHAIN-ERROR)
        (asserts! (> (len activity) u0) ERR-SUPPLY-CHAIN-ERROR)
        
        (map-set supply-chain-tracking
            { product-id: product-id, tracking-id: new-tracking-id }
            {
                timestamp: block-height,
                location: new-location,
                handler: tx-sender,
                activity: activity,
                temperature: temperature,
                humidity: humidity,
                quality-notes: quality-notes,
                verified: true
            }
        )
        
        ;; Update product location and status
        (map-set products
            { product-id: product-id }
            (merge product-data {
                current-location: new-location,
                status: (if (is-eq activity "delivered") PRODUCT-DELIVERED PRODUCT-IN-TRANSIT),
                supply-chain-verified: true
            })
        )
        
        (var-set tracking-counter new-tracking-id)
        (ok new-tracking-id)
    )
)

(define-public (verify-product-authenticity (product-id uint))
    (let
        (
            (product-data (unwrap! (map-get? products { product-id: product-id }) ERR-PRODUCT-NOT-FOUND))
        )
        (ok {
            product-verified: (> (len (get certifications product-data)) u0),
            certifications-count: (len (get certifications product-data)),
            supply-chain-verified: (get supply-chain-verified product-data),
            current-status: (get status product-data),
            farm-id: (get farm-id product-data)
        })
    )
)

(define-public (recall-product (product-id uint))
    (let
        (
            (product-data (unwrap! (map-get? products { product-id: product-id }) ERR-PRODUCT-NOT-FOUND))
        )
        (asserts! (or (is-eq tx-sender CONTRACT-OWNER) (is-eq tx-sender (get producer product-data))) ERR-NOT-AUTHORIZED)
        
        (map-set products
            { product-id: product-id }
            (merge product-data { status: PRODUCT-RECALLED })
        )
        
        (ok true)
    )
)

;; read only functions
;;
(define-read-only (get-product-info (product-id uint))
    (map-get? products { product-id: product-id })
)

(define-read-only (get-authority-info (authority-id uint))
    (map-get? certification-authorities { authority-id: authority-id })
)

(define-read-only (get-product-certification (product-id uint) (certification-id uint))
    (map-get? product-certifications { product-id: product-id, certification-id: certification-id })
)

(define-read-only (get-supply-chain-record (product-id uint) (tracking-id uint))
    (map-get? supply-chain-tracking { product-id: product-id, tracking-id: tracking-id })
)

(define-read-only (get-products-by-producer (producer principal))
    (get product-ids (map-get? producer-products { producer: producer }))
)

(define-read-only (get-product-count)
    (var-get product-counter)
)

(define-read-only (get-authority-count)
    (var-get authority-counter)
)

(define-read-only (is-product-certified (product-id uint))
    (match (map-get? products { product-id: product-id })
        product-data (> (len (get certifications product-data)) u0)
        false
    )
)

(define-read-only (check-certification-validity (product-id uint) (certification-id uint))
    (match (map-get? product-certifications { product-id: product-id, certification-id: certification-id })
        cert-data (some {
            is-valid: (> (get expiry-date cert-data) block-height),
            expiry-date: (get expiry-date cert-data),
            authority-id: (get authority-id cert-data),
            standard-type: (get standard-type cert-data)
        })
        none
    )
)

;; private functions
;;
(define-private (validate-certification-standard (standard uint))
    (or (is-eq standard USDA-ORGANIC)
        (is-eq standard EU-ORGANIC)
        (is-eq standard JAS-ORGANIC)
        (is-eq standard BIODYNAMIC)
        (is-eq standard RAINFOREST-ALLIANCE))
)
