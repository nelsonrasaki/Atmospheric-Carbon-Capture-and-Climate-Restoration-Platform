;; Algae Cultivation Scaling Contract
;; Grows massive algae farms for carbon capture and biofuel production

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-FARM-EXISTS (err u401))
(define-constant ERR-FARM-NOT-FOUND (err u402))
(define-constant ERR-INVALID-DATA (err u403))
(define-constant ERR-INSUFFICIENT-FUNDS (err u404))

;; Data Variables
(define-data-var total-farms uint u0)
(define-data-var total-biomass-produced uint u0)
(define-data-var total-co2-absorbed uint u0)
(define-data-var total-biofuel-produced uint u0)

;; Data Maps
(define-map algae-farms
  { farm-id: uint }
  {
    operator: principal,
    location: (string-ascii 100),
    farm-type: (string-ascii 50),
    cultivation-area: uint,
    algae-species: (string-ascii 50),
    growth-medium: (string-ascii 50),
    co2-source: (string-ascii 50),
    operational-status: bool,
    registration-block: uint
  }
)

(define-map cultivation-cycles
  { farm-id: uint, cycle-id: uint }
  {
    start-date: uint,
    end-date: uint,
    biomass-produced: uint,
    co2-consumed: uint,
    growth-rate: uint,
    harvest-efficiency: uint,
    water-quality: uint,
    verified: bool
  }
)

(define-map biofuel-production
  { farm-id: uint, production-id: uint }
  {
    biomass-input: uint,
    biofuel-output: uint,
    conversion-efficiency: uint,
    energy-content: uint,
    production-date: uint,
    quality-grade: uint,
    verified: bool
  }
)

(define-map environmental-monitoring
  { farm-id: uint, monitoring-period: uint }
  {
    water-temperature: uint,
    ph-level: uint,
    dissolved-oxygen: uint,
    nutrient-levels: uint,
    contamination-score: uint,
    ecosystem-impact: uint,
    verified: bool
  }
)

(define-map operator-farms
  { operator: principal }
  { farm-ids: (list 25 uint) }
)

;; Public Functions

;; Register a new algae farm
(define-public (register-algae-farm (location (string-ascii 100)) (farm-type (string-ascii 50)) (cultivation-area uint) (algae-species (string-ascii 50)) (growth-medium (string-ascii 50)) (co2-source (string-ascii 50)))
  (let
    (
      (farm-id (+ (var-get total-farms) u1))
      (current-farms (default-to { farm-ids: (list) } (map-get? operator-farms { operator: tx-sender })))
    )
    (asserts! (> cultivation-area u0) ERR-INVALID-DATA)
    (asserts! (is-none (map-get? algae-farms { farm-id: farm-id })) ERR-FARM-EXISTS)

    (map-set algae-farms
      { farm-id: farm-id }
      {
        operator: tx-sender,
        location: location,
        farm-type: farm-type,
        cultivation-area: cultivation-area,
        algae-species: algae-species,
        growth-medium: growth-medium,
        co2-source: co2-source,
        operational-status: true,
        registration-block: block-height
      }
    )

    (map-set operator-farms
      { operator: tx-sender }
      { farm-ids: (unwrap! (as-max-len? (append (get farm-ids current-farms) farm-id) u25) ERR-INVALID-DATA) }
    )

    (var-set total-farms farm-id)
    (ok farm-id)
  )
)

;; Record cultivation cycle
(define-public (record-cultivation-cycle (farm-id uint) (cycle-id uint) (biomass-produced uint) (co2-consumed uint) (growth-rate uint) (harvest-efficiency uint) (water-quality uint))
  (let
    (
      (farm (unwrap! (map-get? algae-farms { farm-id: farm-id }) ERR-FARM-NOT-FOUND))
    )
    (asserts! (is-eq (get operator farm) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (get operational-status farm) ERR-INVALID-DATA)
    (asserts! (> biomass-produced u0) ERR-INVALID-DATA)
    (asserts! (> co2-consumed u0) ERR-INVALID-DATA)
    (asserts! (and (>= water-quality u1) (<= water-quality u10)) ERR-INVALID-DATA)

    (map-set cultivation-cycles
      { farm-id: farm-id, cycle-id: cycle-id }
      {
        start-date: (- block-height u100),
        end-date: block-height,
        biomass-produced: biomass-produced,
        co2-consumed: co2-consumed,
        growth-rate: growth-rate,
        harvest-efficiency: harvest-efficiency,
        water-quality: water-quality,
        verified: false
      }
    )

    (var-set total-biomass-produced (+ (var-get total-biomass-produced) biomass-produced))
    (var-set total-co2-absorbed (+ (var-get total-co2-absorbed) co2-consumed))
    (ok true)
  )
)

;; Record biofuel production
(define-public (record-biofuel-production (farm-id uint) (production-id uint) (biomass-input uint) (biofuel-output uint) (energy-content uint))
  (let
    (
      (farm (unwrap! (map-get? algae-farms { farm-id: farm-id }) ERR-FARM-NOT-FOUND))
      (conversion-efficiency (/ (* biofuel-output u100) biomass-input))
      (quality-grade (calculate-quality-grade conversion-efficiency energy-content))
    )
    (asserts! (is-eq (get operator farm) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> biomass-input u0) ERR-INVALID-DATA)
    (asserts! (> biofuel-output u0) ERR-INVALID-DATA)
    (asserts! (> energy-content u0) ERR-INVALID-DATA)

    (map-set biofuel-production
      { farm-id: farm-id, production-id: production-id }
      {
        biomass-input: biomass-input,
        biofuel-output: biofuel-output,
        conversion-efficiency: conversion-efficiency,
        energy-content: energy-content,
        production-date: block-height,
        quality-grade: quality-grade,
        verified: false
      }
    )

    (var-set total-biofuel-produced (+ (var-get total-biofuel-produced) biofuel-output))
    (ok true)
  )
)

;; Record environmental monitoring
(define-public (record-environmental-monitoring (farm-id uint) (monitoring-period uint) (water-temperature uint) (ph-level uint) (dissolved-oxygen uint) (nutrient-levels uint))
  (let
    (
      (farm (unwrap! (map-get? algae-farms { farm-id: farm-id }) ERR-FARM-NOT-FOUND))
      (contamination-score (calculate-contamination-score water-temperature ph-level dissolved-oxygen))
      (ecosystem-impact (calculate-ecosystem-impact contamination-score nutrient-levels))
    )
    (asserts! (is-eq (get operator farm) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= water-temperature u15) (<= water-temperature u35)) ERR-INVALID-DATA)
    (asserts! (and (>= ph-level u60) (<= ph-level u90)) ERR-INVALID-DATA)
    (asserts! (<= dissolved-oxygen u100) ERR-INVALID-DATA)

    (map-set environmental-monitoring
      { farm-id: farm-id, monitoring-period: monitoring-period }
      {
        water-temperature: water-temperature,
        ph-level: ph-level,
        dissolved-oxygen: dissolved-oxygen,
        nutrient-levels: nutrient-levels,
        contamination-score: contamination-score,
        ecosystem-impact: ecosystem-impact,
        verified: false
      }
    )
    (ok true)
  )
)

;; Verify cultivation cycle
(define-public (verify-cultivation-cycle (farm-id uint) (cycle-id uint))
  (let
    (
      (cycle (unwrap! (map-get? cultivation-cycles { farm-id: farm-id, cycle-id: cycle-id }) ERR-FARM-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (not (get verified cycle)) ERR-INVALID-DATA)

    (map-set cultivation-cycles
      { farm-id: farm-id, cycle-id: cycle-id }
      (merge cycle { verified: true })
    )
    (ok true)
  )
)

;; Update farm operational status
(define-public (update-farm-status (farm-id uint) (status bool))
  (let
    (
      (farm (unwrap! (map-get? algae-farms { farm-id: farm-id }) ERR-FARM-NOT-FOUND))
    )
    (asserts! (is-eq (get operator farm) tx-sender) ERR-NOT-AUTHORIZED)

    (map-set algae-farms
      { farm-id: farm-id }
      (merge farm { operational-status: status })
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get farm information
(define-read-only (get-farm-info (farm-id uint))
  (map-get? algae-farms { farm-id: farm-id })
)

;; Get cultivation cycle information
(define-read-only (get-cycle-info (farm-id uint) (cycle-id uint))
  (map-get? cultivation-cycles { farm-id: farm-id, cycle-id: cycle-id })
)

;; Get biofuel production information
(define-read-only (get-production-info (farm-id uint) (production-id uint))
  (map-get? biofuel-production { farm-id: farm-id, production-id: production-id })
)

;; Get environmental monitoring data
(define-read-only (get-monitoring-data (farm-id uint) (monitoring-period uint))
  (map-get? environmental-monitoring { farm-id: farm-id, monitoring-period: monitoring-period })
)

;; Get operator farms
(define-read-only (get-operator-farms (operator principal))
  (map-get? operator-farms { operator: operator })
)

;; Get total statistics
(define-read-only (get-total-stats)
  {
    total-farms: (var-get total-farms),
    total-biomass-produced: (var-get total-biomass-produced),
    total-co2-absorbed: (var-get total-co2-absorbed),
    total-biofuel-produced: (var-get total-biofuel-produced)
  }
)

;; Private Functions

;; Calculate quality grade based on conversion efficiency and energy content
(define-private (calculate-quality-grade (conversion-efficiency uint) (energy-content uint))
  (let
    (
      (efficiency-score (/ conversion-efficiency u10))
      (energy-score (/ energy-content u1000))
    )
    (/ (+ efficiency-score energy-score) u2)
  )
)

;; Calculate contamination score
(define-private (calculate-contamination-score (temperature uint) (ph uint) (oxygen uint))
  (let
    (
      (temp-score (if (and (>= temperature u20) (<= temperature u30)) u10 u5))
      (ph-score (if (and (>= ph u70) (<= ph u80)) u10 u5))
      (oxygen-score (if (>= oxygen u80) u10 u5))
    )
    (/ (+ temp-score ph-score oxygen-score) u3)
  )
)

;; Calculate ecosystem impact
(define-private (calculate-ecosystem-impact (contamination uint) (nutrients uint))
  (/ (+ (* contamination u7) (* nutrients u3)) u10)
)
