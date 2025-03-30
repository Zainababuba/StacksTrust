
;; offspring-will
;; This smart contract allows parents to lock some funds for their child for a certain period before the child can have access to the fund.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Cons, Vars and Maps ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; deployer address
(define-constant deployer tx-sender)

;; contract address
(define-constant contract-address (as-contract tx-sender))

;; A year in blocks
(define-constant year-in-block (* u365 u144))

;; account opening fee
(define-constant account-opening-charge u5000000)

;; Minimun account opening deposit
(define-constant minimum-initial-deposit u5000000)

;; withdrawal fee
(define-constant withdrawal-fee u2)

;; emergency withdrawal fee
(define-constant emergency-withrawal-fee u10)

;; Total fees earned
(define-data-var total-fees-earned uint u0)

;; child account map
(define-map child-account {parent: principal, child-name: (string-ascii 24)}
    {
        child-wallet: principal,
        child-name: (string-ascii 24),
        unlock-height: uint,
        balance: uint,
        admins: (list 5 principal)
    }
)


;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Read Functions ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;

;; Reads the total balance on the contract
(define-read-only (get-contract-balance)
    (stx-get-balance contract-address)
)

;; Reads information about a child's account
(define-read-only (get-account (parent principal) (name (string-ascii 24)))
    (map-get? child-account {parent: parent, child-name: name})
)

;; Read all the total fees accumulated by the contract
(define-read-only (get-total-fees-earned)
    (var-get total-fees-earned)
)

;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Write Functions ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;

;; Create a new offspring will account
(define-public (create-account
                    (child-name (string-ascii 24))
                    (child-wallet principal)
                    (lock-period-in-years uint)
                    (amount uint)
                )
    (let
        (
            (current-total-fees-earned (var-get total-fees-earned))
            (current-child-account (map-get? child-account {parent: tx-sender, child-name: child-name})
            )
            (total-fee-due (+ amount account-opening-charge))
        )
        (asserts! (is-none current-child-account) (err "err-child-account-already-exixts"))
        (asserts! (>= amount minimum-initial-deposit) (err "err-minimum-initial-deposit-is-5stx"))
        (asserts! (>= (stx-get-balance tx-sender) total-fee-due) (err "err-insufficient-balance-to-cover-charges"))
        (unwrap! (stx-transfer? total-fee-due tx-sender contract-address) (err "err-unable-to-send-funds"))
        (var-set total-fees-earned (+ current-total-fees-earned account-opening-charge))
        (ok (map-set child-account {parent: tx-sender, child-name: child-name}
            {
                child-wallet: child-wallet,
                child-name: child-name,
                unlock-height: (+ block-height (* year-in-block lock-period-in-years)),
                balance: amount,
                admins: (list tx-sender)
            }
        ))
    )
)

;; function to fund child account
(define-public (fund-child-account (parent principal) (child-name (string-ascii 24)) (amount uint))
    (let
        (
            (current-child-account (unwrap!
                                        (map-get? child-account {parent: parent, child-name: child-name})
                                        (err "child-account-does-not-exist")
                                    )
            )
            (current-child-balance (get balance current-child-account))
        )
        (unwrap!
            (stx-transfer? amount tx-sender contract-address)
            (err "err-unable-to-fund-child-account")
        )
        (ok (map-set child-account {parent: tx-sender, child-name: child-name}
            (merge
                current-child-account
                {balance: (+ amount current-child-balance)}
            )
        ))
    )
)

;; function to withdraw funds by child when it is matured
(define-public (child-withdraw (parent principal) (child-name (string-ascii 24)))
    (let
        (
            (current-total-fees-earned (var-get total-fees-earned))
            (current-child-account (unwrap!
                                        (map-get? child-account {parent: parent, child-name: child-name})
                                        (err "child-account-does-not-exist")
                                    )
            )
            (current-child-wallet (get child-wallet current-child-account))
            (current-child-balance (get balance current-child-account))
            (current-child-unlock-height (get unlock-height current-child-account))
            (current-withdrawal-fee (/ (* current-child-balance withdrawal-fee) u100))
            (current-child-withdrawal (- current-child-balance current-withdrawal-fee))
        )
        (asserts! (is-eq tx-sender current-child-wallet) (err "err-unauthorized-withdrawal"))
        (asserts! (>= block-height current-child-unlock-height) (err "err-account-not-matured"))
        (unwrap!
            (as-contract (stx-transfer? current-child-withdrawal tx-sender current-child-wallet))
            (err "unable-to-send-stx-to-child-wallet")
        )
        (var-set total-fees-earned (+ current-total-fees-earned current-withdrawal-fee))
        (ok (map-delete child-account {parent: parent, child-name: child-name}))
    )
)
