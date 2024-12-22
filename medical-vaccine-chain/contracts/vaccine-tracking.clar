;; Vaccine Tracking Smart Contract

;; Contract Owner Management
(define-data-var contract-administrator principal tx-sender)

;; Error Codes
(define-constant ERROR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERROR-INVALID-VACCINE-BATCH (err u101))
(define-constant ERROR-DUPLICATE-BATCH (err u102))
(define-constant ERROR-BATCH-UNAVAILABLE (err u103))
(define-constant ERROR-DEPLETED-VACCINE-STOCK (err u104))
(define-constant ERROR-INVALID-PATIENT-IDENTIFIER (err u105))
(define-constant ERROR-DUPLICATE-PATIENT-VACCINATION (err u106))
(define-constant ERROR-STORAGE-TEMPERATURE-VIOLATION (err u107))
(define-constant ERROR-BATCH-PAST-EXPIRATION (err u108))
(define-constant ERROR-INVALID-VACCINATION-SITE (err u109))
(define-constant ERROR-MAXIMUM-VACCINATION-LIMIT (err u110))
(define-constant ERROR-INSUFFICIENT-DOSE-INTERVAL (err u111))
(define-constant ERROR-ADMIN-ONLY-OPERATION (err u112))
(define-constant ERROR-INVALID-DATA-FORMAT (err u113))
(define-constant ERROR-INVALID-EXPIRATION-DATE (err u114))
(define-constant ERROR-INVALID-FACILITY-CAPACITY (err u115))

;; Constants
(define-constant MINIMUM-FREEZER-TEMPERATURE (- 70))
(define-constant MAXIMUM-REFRIGERATION-TEMPERATURE 8)
(define-constant REQUIRED-DAYS-BETWEEN-DOSES u21) ;; 21 days minimum between doses
(define-constant MAXIMUM-ALLOWED-DOSES u4)
(define-constant MINIMUM-DATA-LENGTH u1)
(define-constant CURRENT-BLOCKCHAIN-HEIGHT block-height)

;; Data Maps
(define-map vaccine-inventory
    { batch-identifier: (string-ascii 32) }
    {
        manufacturer-name: (string-ascii 50),
        vaccine-product-name: (string-ascii 50),
        production-date: uint,
        expiration-date: uint,
        remaining-doses: uint,
        required-storage-temperature: int,
        current-batch-status: (string-ascii 20),
        temperature-violation-count: uint,
        storage-location: (string-ascii 100),
        batch-specific-notes: (string-ascii 500)
    }
)

(define-map vaccination-records
    { patient-id: (string-ascii 32) }
    {
        immunization-history: (list 10 {
            administered-batch: (string-ascii 32),
            vaccination-date: uint,
            administered-vaccine: (string-ascii 50),
            dose-number: uint,
            administering-provider: principal,
            administration-location: (string-ascii 100),
            scheduled-next-dose: (optional uint)
        }),
        total-doses-received: uint,
        adverse-reactions: (list 5 (string-ascii 200)),
        medical-exemption: (optional (string-ascii 200))
    }
)

(define-map authorized-providers 
    principal 
    {
        medical-role: (string-ascii 20),
        facility-name: (string-ascii 100),
        license-expiry: uint
    }
)

(define-map storage-facilities
    (string-ascii 100)
    {
        physical-location: (string-ascii 200),
        storage-capacity-limit: uint,
        current-stock-level: uint,
        temperature-log: (list 100 {
            monitoring-time: uint,
            measured-temperature: int
        })
    }
)

;; Private Functions
(define-private (is-contract-administrator)
    (is-eq tx-sender (var-get contract-administrator))
)

;; Principal validation function
(define-private (is-valid-principal (address principal))
    (and 
        (not (is-eq address tx-sender))  ;; Prevent self-assignment
        (not (is-eq address (var-get contract-administrator)))  ;; Prevent current admin reassignment
        (match (principal-destruct? address)
            success true  ;; If principal-destruct succeeds, the principal is valid
            error false) ;; If it fails, the principal is invalid
    )
)

;; String validation functions
(define-private (validate-short-string (input (string-ascii 32)))
    (> (len input) MINIMUM-DATA-LENGTH)
)

(define-private (validate-very-short-string (input (string-ascii 20)))
    (> (len input) MINIMUM-DATA-LENGTH)
)

(define-private (validate-medium-string (input (string-ascii 50)))
    (> (len input) MINIMUM-DATA-LENGTH)
)

(define-private (validate-long-string (input (string-ascii 100)))
    (> (len input) MINIMUM-DATA-LENGTH)
)

(define-private (validate-extended-string (input (string-ascii 200)))
    (> (len input) MINIMUM-DATA-LENGTH)
)

(define-private (validate-future-timestamp (timestamp uint))
    (> timestamp CURRENT-BLOCKCHAIN-HEIGHT)
)

(define-private (validate-facility-capacity (proposed-capacity uint))
    (> proposed-capacity u0)
)

;; Read-only Functions
(define-read-only (get-contract-administrator)
    (ok (var-get contract-administrator))
)

(define-read-only (verify-provider-authorization (provider-address principal))
    (match (map-get? authorized-providers provider-address)
        provider-details (>= (get license-expiry provider-details) CURRENT-BLOCKCHAIN-HEIGHT)
        false
    )
)

;; Public Functions
(define-public (transfer-administrator-rights (new-administrator principal))
    (begin
        (asserts! (is-contract-administrator) ERROR-ADMIN-ONLY-OPERATION)
        (asserts! (is-valid-principal new-administrator) ERROR-INVALID-DATA-FORMAT)
        (ok (var-set contract-administrator new-administrator))
    )
)

(define-public (register-medical-provider 
    (provider-address principal)
    (medical-role (string-ascii 20))
    (facility-name (string-ascii 100))
    (license-expiry uint))
    (begin
        (asserts! (is-contract-administrator) ERROR-UNAUTHORIZED-ACCESS)
        (asserts! (is-valid-principal provider-address) ERROR-INVALID-DATA-FORMAT)
        (asserts! (validate-very-short-string medical-role) ERROR-INVALID-DATA-FORMAT)
        (asserts! (validate-long-string facility-name) ERROR-INVALID-DATA-FORMAT)
        (asserts! (validate-future-timestamp license-expiry) ERROR-INVALID-EXPIRATION-DATE)
        (ok (map-set authorized-providers 
            provider-address 
            {
                medical-role: medical-role,
                facility-name: facility-name,
                license-expiry: license-expiry
            }))
    )
)

(define-public (register-facility
    (facility-identifier (string-ascii 100))
    (physical-address (string-ascii 200))
    (storage-capacity-limit uint))
    (begin
        (asserts! (is-contract-administrator) ERROR-UNAUTHORIZED-ACCESS)
        (asserts! (validate-long-string facility-identifier) ERROR-INVALID-DATA-FORMAT)
        (asserts! (validate-extended-string physical-address) ERROR-INVALID-DATA-FORMAT)
        (asserts! (validate-facility-capacity storage-capacity-limit) ERROR-INVALID-FACILITY-CAPACITY)
        (ok (map-set storage-facilities
            facility-identifier
            {
                physical-location: physical-address,
                storage-capacity-limit: storage-capacity-limit,
                current-stock-level: u0,
                temperature-log: (list)
            }))
    )
)

(define-public (register-vaccine-batch 
    (batch-identifier (string-ascii 32))
    (manufacturer-name (string-ascii 50))
    (vaccine-product-name (string-ascii 50))
    (production-date uint)
    (expiration-date uint)
    (initial-stock uint)
    (required-storage-temperature int)
    (storage-location (string-ascii 100)))
    (begin
        (asserts! (verify-provider-authorization tx-sender) ERROR-UNAUTHORIZED-ACCESS)
        (asserts! (validate-short-string batch-identifier) ERROR-INVALID-DATA-FORMAT)
        (asserts! (validate-medium-string manufacturer-name) ERROR-INVALID-DATA-FORMAT)
        (asserts! (validate-medium-string vaccine-product-name) ERROR-INVALID-DATA-FORMAT)
        (asserts! (validate-long-string storage-location) ERROR-INVALID-DATA-FORMAT)
        (asserts! (is-none (map-get? vaccine-inventory {batch-identifier: batch-identifier})) ERROR-DUPLICATE-BATCH)
        (asserts! (validate-facility-capacity initial-stock) ERROR-INVALID-VACCINE-BATCH)
        (asserts! (validate-future-timestamp expiration-date) ERROR-INVALID-EXPIRATION-DATE)
        (asserts! (> expiration-date production-date) ERROR-INVALID-VACCINE-BATCH)
        (asserts! (and (>= required-storage-temperature MINIMUM-FREEZER-TEMPERATURE) 
                      (<= required-storage-temperature MAXIMUM-REFRIGERATION-TEMPERATURE)) 
                 ERROR-STORAGE-TEMPERATURE-VIOLATION)
        
        (ok (map-set vaccine-inventory 
            {batch-identifier: batch-identifier}
            {
                manufacturer-name: manufacturer-name,
                vaccine-product-name: vaccine-product-name,
                production-date: production-date,
                expiration-date: expiration-date,
                remaining-doses: initial-stock,
                required-storage-temperature: required-storage-temperature,
                current-batch-status: "active",
                temperature-violation-count: u0,
                storage-location: storage-location,
                batch-specific-notes: ""
            }))
    )
)

(define-public (update-batch-status
    (batch-identifier (string-ascii 32))
    (updated-status (string-ascii 20)))
    (begin
        (asserts! (verify-provider-authorization tx-sender) ERROR-UNAUTHORIZED-ACCESS)
        (asserts! (validate-short-string batch-identifier) ERROR-INVALID-DATA-FORMAT)
        (asserts! (validate-very-short-string updated-status) ERROR-INVALID-DATA-FORMAT)
        (match (map-get? vaccine-inventory {batch-identifier: batch-identifier})
            batch-details (ok (map-set vaccine-inventory 
                {batch-identifier: batch-identifier}
                (merge batch-details {current-batch-status: updated-status})))
            ERROR-BATCH-UNAVAILABLE
        )
    )
)

(define-public (record-temperature-violation
    (batch-identifier (string-ascii 32))
    (recorded-temperature int))
    (begin
        (asserts! (verify-provider-authorization tx-sender) ERROR-UNAUTHORIZED-ACCESS)
        (asserts! (validate-short-string batch-identifier) ERROR-INVALID-DATA-FORMAT)
        (match (map-get? vaccine-inventory {batch-identifier: batch-identifier})
            batch-details (ok (map-set vaccine-inventory 
                {batch-identifier: batch-identifier}
                (merge batch-details {
                    temperature-violation-count: (+ (get temperature-violation-count batch-details) u1),
                    current-batch-status: (if (> (get temperature-violation-count batch-details) u2) 
                                    "compromised" 
                                    (get current-batch-status batch-details))
                })))
            ERROR-BATCH-UNAVAILABLE
        )
    )
)

(define-public (record-vaccination
    (patient-id (string-ascii 32))
    (batch-identifier (string-ascii 32))
    (vaccination-site (string-ascii 100)))
    (begin
        (asserts! (verify-provider-authorization tx-sender) ERROR-UNAUTHORIZED-ACCESS)
        (asserts! (validate-short-string patient-id) ERROR-INVALID-PATIENT-IDENTIFIER)
        (asserts! (validate-short-string batch-identifier) ERROR-INVALID-DATA-FORMAT)
        (asserts! (validate-long-string vaccination-site) ERROR-INVALID-VACCINATION-SITE)
        
        (match (map-get? vaccine-inventory {batch-identifier: batch-identifier})
            batch-details (begin
                (asserts! (> (get remaining-doses batch-details) u0) ERROR-DEPLETED-VACCINE-STOCK)
                (asserts! (is-eq (get current-batch-status batch-details) "active") ERROR-INVALID-VACCINE-BATCH)
                (asserts! (<= CURRENT-BLOCKCHAIN-HEIGHT (get expiration-date batch-details)) ERROR-BATCH-PAST-EXPIRATION)
                
                (match (map-get? vaccination-records {patient-id: patient-id})
                    patient-record (begin
                        (asserts! (< (get total-doses-received patient-record) MAXIMUM-ALLOWED-DOSES) 
                                ERROR-MAXIMUM-VACCINATION-LIMIT)
                        (let ((current-dose (+ (get total-doses-received patient-record) u1)))
                            (if (> current-dose u1)
                                (asserts! (>= (- CURRENT-BLOCKCHAIN-HEIGHT 
                                    (get vaccination-date (unwrap-panic (element-at 
                                        (get immunization-history patient-record) 
                                        (- current-dose u2))))) 
                                    REQUIRED-DAYS-BETWEEN-DOSES)
                                    ERROR-INSUFFICIENT-DOSE-INTERVAL)
                                true
                            )
                            
                            (ok (map-set vaccination-records
                                {patient-id: patient-id}
                                {
                                    immunization-history: (unwrap-panic (as-max-len? 
                                        (append (get immunization-history patient-record)
                                            {
                                                administered-batch: batch-identifier,
                                                vaccination-date: CURRENT-BLOCKCHAIN-HEIGHT,
                                                administered-vaccine: (get vaccine-product-name batch-details),
                                                dose-number: current-dose,
                                                administering-provider: tx-sender,
                                                administration-location: vaccination-site,
                                                scheduled-next-dose: (some (+ CURRENT-BLOCKCHAIN-HEIGHT REQUIRED-DAYS-BETWEEN-DOSES))
                                            }
                                        ) u10)),
                                    total-doses-received: current-dose,
                                    adverse-reactions: (get adverse-reactions patient-record),
                                    medical-exemption: (get medical-exemption patient-record)
                                }))))
                    ;; First dose for patient
                    (ok (map-set vaccination-records
                        {patient-id: patient-id}
                        {
                            immunization-history: (list 
                                {
                                    administered-batch: batch-identifier,
                                    vaccination-date: CURRENT-BLOCKCHAIN-HEIGHT,
                                    administered-vaccine: (get vaccine-product-name batch-details),
                                    dose-number: u1,
                                    administering-provider: tx-sender,
                                    administration-location: vaccination-site,
                                    scheduled-next-dose: (some (+ CURRENT-BLOCKCHAIN-HEIGHT REQUIRED-DAYS-BETWEEN-DOSES))
                                }),
                            total-doses-received: u1,
                            adverse-reactions: (list),
                            medical-exemption: none
                        })))
            )
            ERROR-BATCH-UNAVAILABLE
        )
    )
)

;; Read-only Functions
(define-read-only (get-batch-details (batch-identifier (string-ascii 32)))
    (map-get? vaccine-inventory {batch-identifier: batch-identifier})
)

(define-read-only (get-patient-record (patient-id (string-ascii 32)))
    (map-get? vaccination-records {patient-id: patient-id})
)

(define-read-only (get-facility-details (facility-identifier (string-ascii 100)))
    (map-get? storage-facilities facility-identifier)
)

(define-read-only (verify-batch-validity (batch-identifier (string-ascii 32)))
    (match (map-get? vaccine-inventory {batch-identifier: batch-identifier})
        batch-details (and
            (is-eq (get current-batch-status batch-details) "active")
            (> (get remaining-doses batch-details) u0)
            (<= CURRENT-BLOCKCHAIN-HEIGHT (get expiration-date batch-details))
            (<= (get temperature-violation-count batch-details) u2))
        false
    )
)