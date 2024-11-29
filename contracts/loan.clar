(define-constant ERR-LOAN-EXISTS 1000)
(define-constant ERR-LOAN-NOT-FOUND 1001)
(define-constant ERR-NOT-BORROWER 1002)
(define-constant ERR-NOT-LENDER 1003)
(define-constant ERR-INSUFFICIENT-COLLATERAL 1004)
(define-constant ERR-NOT-DUE-YET 1005)
(define-constant ERR-LOAN-ALREADY-ACCEPTED 1006)
(define-constant ERR-LOAN-ALREADY-DEFAULTED 1007)
(define-constant ERR-TRANSFER-FAILED 1008)
(define-constant ERR-COLLATERAL-TRANSFER-FAILED 1009)

(define-constant STATUS-OPEN u0)
(define-constant STATUS-ACTIVE u1)
(define-constant STATUS-DEFAULTED u2)

(define-map loans
  uint  ;; loan-id as a key type (unsigned integer)
  {
    principal: uint,
    collateral: uint,
    interest-rate: uint,
    due-block: uint,
    lender: principal,
    borrower: (optional principal),
    status: uint
  }
)

(define-public (create-loan (loan-id uint) (principal-amount uint) (interest-rate uint) (due-block uint))
  (begin
    (asserts! (is-none (map-get? loans loan-id)) (err ERR-LOAN-EXISTS))
    (map-insert loans loan-id 
    {
      principal: principal-amount,
      collateral: u0,
      interest-rate: interest-rate,
      due-block: due-block,
      lender: tx-sender,
      borrower: none,
      status: STATUS-OPEN
    })
    (print {action: "Loan created", loan-id: loan-id, lender: tx-sender})
    (ok loan-id)
  )
)


(define-public (accept-loan (loan-id uint) (collateral uint))
  (let ((loan (map-get? loans loan-id)))
    (asserts! (is-some loan) (err ERR-LOAN-NOT-FOUND))
    (let ((loan-details (unwrap-panic loan)))
      (asserts! (> (get principal loan-details) u0) (err ERR-INSUFFICIENT-COLLATERAL))
      (asserts! (is-eq (get status loan-details) STATUS-OPEN) (err ERR-LOAN-ALREADY-ACCEPTED))
      (asserts! (>= collateral (* (get principal loan-details) (/ u20 u100))) (err ERR-INSUFFICIENT-COLLATERAL))
      (map-set loans loan-id
        (tuple
          (principal (get principal loan-details))
          (collateral collateral)
          (interest-rate (get interest-rate loan-details))
          (due-block (get due-block loan-details))
          (lender (get lender loan-details))
          (borrower (some tx-sender))
          (status STATUS-ACTIVE)))
      (print {action: "Loan accepted", loan-id: loan-id, borrower: tx-sender})
      (ok true))))

(define-public (repay-loan (loan-id uint))
  (let ((loan (map-get? loans loan-id)))
    (asserts! (is-some loan) (err ERR-LOAN-NOT-FOUND))
    (let ((loan-details (unwrap-panic loan)))
      (asserts! (is-some (get borrower loan-details)) (err ERR-NOT-BORROWER))
      (asserts! (is-eq (unwrap-panic (get borrower loan-details)) tx-sender) (err ERR-NOT-BORROWER))
      (asserts! (is-eq (get status loan-details) STATUS-ACTIVE) (err ERR-LOAN-ALREADY-DEFAULTED))
      (let ((total-owed (+ (get principal loan-details) (* (get principal loan-details) (/ u20 u100)))))
        (asserts! (>= (stx-get-balance tx-sender) total-owed) (err ERR-INSUFFICIENT-COLLATERAL))
        (match (stx-transfer? total-owed tx-sender (get lender loan-details))
          transfer-result 
          (begin 
            (map-delete loans loan-id)
            (print {action: "Loan repaid", loan-id: loan-id, borrower: tx-sender})
            (ok true))
          transfer-err 
          (err ERR-TRANSFER-FAILED)))))
)

(define-public (claim-collateral (loan-id uint))
  (let ((loan (map-get? loans loan-id)))
    (asserts! (is-some loan) (err ERR-LOAN-NOT-FOUND))
    (let ((loan-details (unwrap-panic loan)))
      (asserts! (is-eq (get lender loan-details) tx-sender) (err ERR-NOT-LENDER))
      (asserts! (>= block-height (get due-block loan-details)) (err ERR-NOT-DUE-YET))
      (asserts! (is-eq (get status loan-details) STATUS-ACTIVE) (err ERR-LOAN-ALREADY-DEFAULTED))
      (map-set loans loan-id
        {
          principal: (get principal loan-details),
          collateral: (get collateral loan-details),
          interest-rate: (get interest-rate loan-details),
          due-block: (get due-block loan-details),
          lender: (get lender loan-details),
          borrower: (get borrower loan-details),
          status: STATUS-DEFAULTED
        })
      (match (stx-transfer? 
               (get collateral loan-details) 
               (unwrap-panic (get borrower loan-details)) 
               tx-sender)
        transfer-result 
        (begin 
          (print {action: "Collateral claimed", loan-id: loan-id, lender: tx-sender})
          (ok true))
        transfer-err 
        (err ERR-COLLATERAL-TRANSFER-FAILED))
  ))
)

(define-public (get-loan-details (loan-id uint))
  (match (map-get? loans loan-id)
    loan (ok loan)
    (err ERR-LOAN-NOT-FOUND)))