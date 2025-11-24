;; PredictionMarket - Decentralized Prediction Markets
;; Event outcomes, betting pools, and oracle resolution

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-market-closed (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-already-resolved (err u105))
(define-constant err-not-resolved (err u106))

(define-data-var next-market-id uint u1)
(define-data-var next-position-id uint u1)
(define-data-var total-volume uint u0)

(define-map markets
  uint
  {
    creator: principal,
    question: (string-ascii 256),
    description: (string-ascii 512),
    category: (string-ascii 32),
    total-pool: uint,
    yes-pool: uint,
    no-pool: uint,
    resolution-deadline: uint,
    trading-deadline: uint,
    resolved: bool,
    outcome: (optional bool),
    oracle: principal,
    created-at: uint
  }
)

(define-map positions
  uint
  {
    market-id: uint,
    trader: principal,
    prediction: bool,
    amount: uint,
    odds-at-entry: uint,
    claimed: bool,
    created-at: uint
  }
)

(define-map user-positions
  {market-id: uint, trader: principal}
  (list 20 uint)
)

(define-map trader-stats
  principal
  {
    total-wagered: uint,
    total-won: uint,
    markets-traded: uint,
    win-rate: uint
  }
)

(define-map market-categories
  (string-ascii 32)
  {
    total-markets: uint,
    total-volume: uint
  }
)

(define-map oracle-registry
  principal
  {
    name: (string-ascii 64),
    reputation: uint,
    markets-resolved: uint,
    disputes: uint,
    active: bool
  }
)

(define-public (register-oracle (name (string-ascii 64)))
  (begin
    (map-set oracle-registry tx-sender {
      name: name,
      reputation: u100,
      markets-resolved: u0,
      disputes: u0,
      active: true
    })

    (print {event: "oracle-registered", oracle: tx-sender})
    (ok true)
  )
)

(define-public (create-market
    (question (string-ascii 256))
    (description (string-ascii 512))
    (category (string-ascii 32))
    (resolution-deadline uint)
    (trading-duration uint)
    (oracle principal))
  (let ((market-id (var-get next-market-id)))
    (asserts! (is-some (map-get? oracle-registry oracle)) err-not-found)
    (asserts! (> resolution-deadline block-height) err-market-closed)

    (map-set markets market-id {
      creator: tx-sender,
      question: question,
      description: description,
      category: category,
      total-pool: u0,
      yes-pool: u0,
      no-pool: u0,
      resolution-deadline: resolution-deadline,
      trading-deadline: (+ block-height trading-duration),
      resolved: false,
      outcome: none,
      oracle: oracle,
      created-at: block-height
    })

    (var-set next-market-id (+ market-id u1))

    (print {event: "market-created", market-id: market-id, creator: tx-sender})
    (ok market-id)
  )
)

(define-public (place-bet (market-id uint) (prediction bool) (amount uint))
  (let (
    (market (unwrap! (map-get? markets market-id) err-not-found))
    (position-id (var-get next-position-id))
    (current-odds (calculate-odds market-id prediction))
  )
    (asserts! (not (get resolved market)) err-already-resolved)
    (asserts! (< block-height (get trading-deadline market)) err-market-closed)
    (asserts! (> amount u0) err-invalid-amount)

    (map-set positions position-id {
      market-id: market-id,
      trader: tx-sender,
      prediction: prediction,
      amount: amount,
      odds-at-entry: current-odds,
      claimed: false,
      created-at: block-height
    })

    (map-set markets market-id
      (merge market {
        total-pool: (+ (get total-pool market) amount),
        yes-pool: (if prediction (+ (get yes-pool market) amount) (get yes-pool market)),
        no-pool: (if prediction (get no-pool market) (+ (get no-pool market) amount))
      }))

    (var-set next-position-id (+ position-id u1))
    (var-set total-volume (+ (var-get total-volume) amount))

    (let ((trader (default-to
          {total-wagered: u0, total-won: u0, markets-traded: u0, win-rate: u0}
          (map-get? trader-stats tx-sender))))
      (map-set trader-stats tx-sender
        (merge trader {
          total-wagered: (+ (get total-wagered trader) amount),
          markets-traded: (+ (get markets-traded trader) u1)
        }))
    )

    (print {event: "bet-placed", market-id: market-id, trader: tx-sender, amount: amount})
    (ok position-id)
  )
)

(define-public (resolve-market (market-id uint) (outcome bool))
  (let ((market (unwrap! (map-get? markets market-id) err-not-found)))
    (asserts! (is-eq tx-sender (get oracle market)) err-unauthorized)
    (asserts! (not (get resolved market)) err-already-resolved)
    (asserts! (>= block-height (get resolution-deadline market)) err-market-closed)

    (map-set markets market-id
      (merge market {
        resolved: true,
        outcome: (some outcome)
      }))

    (let ((oracle-profile (unwrap! (map-get? oracle-registry tx-sender) err-not-found)))
      (map-set oracle-registry tx-sender
        (merge oracle-profile {
          markets-resolved: (+ (get markets-resolved oracle-profile) u1),
          reputation: (+ (get reputation oracle-profile) u5)
        }))
    )

    (print {event: "market-resolved", market-id: market-id, outcome: outcome})
    (ok true)
  )
)

(define-public (claim-winnings (position-id uint))
  (let (
    (position (unwrap! (map-get? positions position-id) err-not-found))
    (market (unwrap! (map-get? markets (get market-id position)) err-not-found))
  )
    (asserts! (is-eq (get trader position) tx-sender) err-unauthorized)
    (asserts! (get resolved market) err-not-resolved)
    (asserts! (not (get claimed position)) err-already-resolved)

    (let ((outcome (unwrap! (get outcome market) err-not-resolved)))
      (if (is-eq (get prediction position) outcome)
        (let (
          (winning-pool (if outcome (get yes-pool market) (get no-pool market)))
          (total-pool (get total-pool market))
          (payout (/ (* (get amount position) total-pool) winning-pool))
        )
          (map-set positions position-id (merge position {claimed: true}))

          (let ((trader (unwrap! (map-get? trader-stats tx-sender) err-not-found)))
            (map-set trader-stats tx-sender
              (merge trader {total-won: (+ (get total-won trader) payout)}))
          )

          (print {event: "winnings-claimed", position-id: position-id, amount: payout})
          (ok payout)
        )
        (begin
          (map-set positions position-id (merge position {claimed: true}))
          (print {event: "position-lost", position-id: position-id})
          (ok u0)
        )
      )
    )
  )
)

(define-public (dispute-resolution (market-id uint) (reason (string-ascii 256)))
  (let (
    (market (unwrap! (map-get? markets market-id) err-not-found))
    (oracle-profile (unwrap! (map-get? oracle-registry (get oracle market)) err-not-found))
  )
    (asserts! (get resolved market) err-not-resolved)

    (map-set oracle-registry (get oracle market)
      (merge oracle-profile {
        disputes: (+ (get disputes oracle-profile) u1),
        reputation: (if (> (get reputation oracle-profile) u10)
                      (- (get reputation oracle-profile) u10)
                      u0)
      }))

    (print {event: "resolution-disputed", market-id: market-id, disputer: tx-sender})
    (ok true)
  )
)

(define-public (cancel-market (market-id uint))
  (let ((market (unwrap! (map-get? markets market-id) err-not-found)))
    (asserts! (is-eq (get creator market) tx-sender) err-unauthorized)
    (asserts! (not (get resolved market)) err-already-resolved)
    (asserts! (< block-height (get trading-deadline market)) err-market-closed)

    (map-set markets market-id (merge market {resolved: true, outcome: none}))

    (print {event: "market-cancelled", market-id: market-id})
    (ok true)
  )
)

(define-private (calculate-odds (market-id uint) (prediction bool))
  (match (map-get? markets market-id)
    market (if prediction
      (if (is-eq (get yes-pool market) u0)
        u100
        (/ (* (get total-pool market) u100) (get yes-pool market)))
      (if (is-eq (get no-pool market) u0)
        u100
        (/ (* (get total-pool market) u100) (get no-pool market))))
    u100
  )
)

(define-read-only (get-market (market-id uint))
  (map-get? markets market-id)
)

(define-read-only (get-position (position-id uint))
  (map-get? positions position-id)
)

(define-read-only (get-trader-stats (trader principal))
  (map-get? trader-stats trader)
)

(define-read-only (get-oracle-profile (oracle principal))
  (map-get? oracle-registry oracle)
)

(define-read-only (get-current-odds (market-id uint) (prediction bool))
  (ok (calculate-odds market-id prediction))
)

(define-read-only (get-platform-stats)
  (ok {
    total-volume: (var-get total-volume),
    total-markets: (- (var-get next-market-id) u1)
  })
)
