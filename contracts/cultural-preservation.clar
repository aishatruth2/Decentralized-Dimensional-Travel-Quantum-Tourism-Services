;; Cultural Preservation Contract
;; Preserves dimensional travel destinations

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_SITE_NOT_FOUND (err u501))
(define-constant ERR_INVALID_STATUS (err u502))

;; Preservation status constants
(define-constant STATUS_PROTECTED u1)
(define-constant STATUS_MONITORED u2)
(define-constant STATUS_RESTRICTED u3)
(define-constant STATUS_CLOSED u4)

;; Cultural site data structure
(define-map cultural-sites
  { site-id: uint }
  {
    dimension: (string-ascii 50),
    name: (string-ascii 100),
    cultural-significance: uint,
    preservation-status: uint,
    visitor-limit: uint,
    current-visitors: uint,
    guardian: principal,
    protection-level: uint,
    created-at: uint
  }
)

;; Impact assessments
(define-map impact-assessments
  { assessment-id: uint }
  {
    site-id: uint,
    assessor: principal,
    cultural-impact-score: uint,
    environmental-impact: uint,
    recommendations: (string-ascii 200),
    assessment-date: uint
  }
)

(define-data-var next-site-id uint u1)
(define-data-var next-assessment-id uint u1)

;; Register cultural site
(define-public (register-cultural-site
  (dimension (string-ascii 50))
  (name (string-ascii 100))
  (significance uint)
  (visitor-limit uint)
  (protection-level uint)
)
  (let ((site-id (var-get next-site-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set cultural-sites
      { site-id: site-id }
      {
        dimension: dimension,
        name: name,
        cultural-significance: significance,
        preservation-status: STATUS_PROTECTED,
        visitor-limit: visitor-limit,
        current-visitors: u0,
        guardian: tx-sender,
        protection-level: protection-level,
        created-at: block-height
      }
    )
    (var-set next-site-id (+ site-id u1))
    (ok site-id)
  )
)

;; Update visitor count
(define-public (update-visitor-count (site-id uint) (visitor-change int))
  (match (map-get? cultural-sites { site-id: site-id })
    site (begin
      (let ((new-count (if (> visitor-change 0)
                         (+ (get current-visitors site) (to-uint visitor-change))
                         (if (>= (get current-visitors site) (to-uint (* visitor-change -1)))
                           (- (get current-visitors site) (to-uint (* visitor-change -1)))
                           u0))))
        (map-set cultural-sites
          { site-id: site-id }
          (merge site { current-visitors: new-count })
        )
        (ok new-count)
      )
    )
    ERR_SITE_NOT_FOUND
  )
)

;; Create impact assessment
(define-public (create-impact-assessment
  (site-id uint)
  (cultural-score uint)
  (environmental-score uint)
  (recommendations (string-ascii 200))
)
  (let ((assessment-id (var-get next-assessment-id)))
    (map-set impact-assessments
      { assessment-id: assessment-id }
      {
        site-id: site-id,
        assessor: tx-sender,
        cultural-impact-score: cultural-score,
        environmental-impact: environmental-score,
        recommendations: recommendations,
        assessment-date: block-height
      }
    )
    (var-set next-assessment-id (+ assessment-id u1))
    (ok assessment-id)
  )
)

;; Get cultural site
(define-read-only (get-cultural-site (site-id uint))
  (map-get? cultural-sites { site-id: site-id })
)

;; Check if site can accept visitors
(define-read-only (can-accept-visitors (site-id uint))
  (match (map-get? cultural-sites { site-id: site-id })
    site (ok (< (get current-visitors site) (get visitor-limit site)))
    ERR_SITE_NOT_FOUND
  )
)

;; Get impact assessment
(define-read-only (get-impact-assessment (assessment-id uint))
  (map-get? impact-assessments { assessment-id: assessment-id })
)
