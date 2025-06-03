;; Experience Optimization Contract
;; Optimizes dimensional travel experiences

(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_EXPERIENCE_NOT_FOUND (err u401))
(define-constant ERR_INVALID_RATING (err u402))

;; Experience data structure
(define-map experiences
  { experience-id: uint }
  {
    journey-id: uint,
    traveler: principal,
    provider-id: uint,
    dimension-visited: (string-ascii 50),
    experience-rating: uint,
    cultural-impact: uint,
    quantum-resonance: uint,
    feedback: (string-ascii 200),
    timestamp: uint
  }
)

;; Optimization recommendations
(define-map recommendations
  { dimension: (string-ascii 50) }
  {
    best-time-to-visit: uint,
    recommended-duration: uint,
    cultural-sensitivity-level: uint,
    quantum-stability: uint,
    average-rating: uint,
    total-visits: uint
  }
)

(define-data-var next-experience-id uint u1)

;; Record travel experience
(define-public (record-experience
  (journey-id uint)
  (provider-id uint)
  (dimension (string-ascii 50))
  (rating uint)
  (cultural-impact uint)
  (quantum-resonance uint)
  (feedback (string-ascii 200))
)
  (let ((experience-id (var-get next-experience-id)))
    (asserts! (and (>= rating u1) (<= rating u5)) ERR_INVALID_RATING)
    (asserts! (and (>= cultural-impact u1) (<= cultural-impact u5)) ERR_INVALID_RATING)
    (asserts! (and (>= quantum-resonance u1) (<= quantum-resonance u5)) ERR_INVALID_RATING)

    (map-set experiences
      { experience-id: experience-id }
      {
        journey-id: journey-id,
        traveler: tx-sender,
        provider-id: provider-id,
        dimension-visited: dimension,
        experience-rating: rating,
        cultural-impact: cultural-impact,
        quantum-resonance: quantum-resonance,
        feedback: feedback,
        timestamp: block-height
      }
    )

    ;; Update dimension recommendations
    (update-dimension-stats dimension rating)
    (var-set next-experience-id (+ experience-id u1))
    (ok experience-id)
  )
)

;; Update dimension statistics
(define-private (update-dimension-stats (dimension (string-ascii 50)) (rating uint))
  (match (map-get? recommendations { dimension: dimension })
    current-rec (begin
      (let ((new-total (+ (get total-visits current-rec) u1))
            (new-avg (/ (+ (* (get average-rating current-rec) (get total-visits current-rec)) rating) new-total)))
        (map-set recommendations
          { dimension: dimension }
          (merge current-rec {
            average-rating: new-avg,
            total-visits: new-total
          })
        )
      )
    )
    (map-set recommendations
      { dimension: dimension }
      {
        best-time-to-visit: block-height,
        recommended-duration: u7,
        cultural-sensitivity-level: u3,
        quantum-stability: u4,
        average-rating: rating,
        total-visits: u1
      }
    )
  )
)

;; Get experience details
(define-read-only (get-experience (experience-id uint))
  (map-get? experiences { experience-id: experience-id })
)

;; Get dimension recommendations
(define-read-only (get-dimension-recommendations (dimension (string-ascii 50)))
  (map-get? recommendations { dimension: dimension })
)
