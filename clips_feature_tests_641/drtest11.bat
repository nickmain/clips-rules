(clear)                   ; Optimized Rete Evaluator Issue

(defrule rule-1
   (factoid ?x ?y&:(and ?x ?y)) ; FactPNGetVar3
   =>)

(defrule rule-2
   (factoid ?x ?y)
   (test (and ?x ?y)) ; FactJNGetVar3
   =>)

(defrule rule-3
   (factoid $? ?x ?y&:(and ?x ?y) $?) ; FactPNGetVar1
   =>)

(defrule rule-4
   (factoid $? ?x ?y $?)
   (test (and ?x ?y)) ; FactJNGetVar1
   =>)
(defglobal ?*z* = FALSE)

(defrule rule-5
   (factoid ? ?)
   (test (and ?*z* ?*z*))
   =>)
(assert (factoid FALSE FALSE))
(agenda)
(assert (factoid "FALSE" "FALSE"))
(agenda)
(clear)

(deftemplate factoid
   (slot s1)
   (slot s2))

(defrule rule-1
   (factoid (s1 ?x) (s2 ?y&:(and ?x ?y))) ; FactPNGetVar2
   =>)

(defrule rule-2
   (factoid (s1 ?x) (s2 ?y))
   (test (and ?x ?y)) ; FactJNGetVar2
   =>)
(assert (factoid (s1 FALSE) (s2 FALSE)))
(agenda)
(assert (factoid (s1 "FALSE") (s2 "FALSE")))
(agenda)
(clear)

(defclass OBJOID1
   (is-a USER)
   (slot s1)
   (slot s2))

(defclass OBJOID2
   (is-a USER)
   (multislot ms1))

(defrule rule-1
   (object 
      (is-a OBJOID1)
      (s1 ?x)
      (s2 ?y&:(and ?x ?y))) ; ObjectGetVarPNFunction1
   =>)

(defrule rule-2
   (object 
      (is-a OBJOID1)
      (s1 ?x)
      (s2 ?y))
   (test (and ?x ?y)) ; ObjectGetVarJNFunction1
   =>)

(defrule rule-3
   (object 
      (is-a OBJOID2)
      (ms1 $? ?x ?y&:(and ?x ?y))) ; ObjectGetVarPNFunction2
   =>)
   
(defrule rule-4
   (object 
      (is-a OBJOID2)
      (ms1 $? ?x ?y))
   (test (and ?x ?y)) ; ObjectGetVarJNFunction2
   =>)
(make-instance o1 of OBJOID1 (s1 FALSE) (s2 FALSE))
(make-instance o2 of OBJOID2 (ms1 FALSE FALSE))
(agenda)
(make-instance o3 of OBJOID1 (s1 "FALSE") (s2 "FALSE"))
(make-instance o4 of OBJOID2 (ms1 "FALSE" "FALSE"))
(agenda)
(clear) ; load-facts GC issue

(defglobal MAIN ?*key-id* = 0
                ?*reasmb-id* = 1)

(deffunction key-id ()
   (bind ?*key-id* (+ ?*key-id* 1))
   (bind ?*reasmb-id* 1)
   (return ?*key-id*))
   
(deftemplate key 
   (slot weight (default 1))
   (slot id (default-dynamic (key-id))))
         
(deffunction reasmb-id ()
   (bind ?rv (create$ ?*key-id* 
                      ?*reasmb-id*))
   (bind ?*reasmb-id* (+ ?*reasmb-id* 1))
   (return ?rv))

(deftemplate reasmb
   (multislot id (default-dynamic (reasmb-id))))
(load-facts buglfgc.fct)
(facts)
(clear) ; Modify/duplicate ordered fact
(assert (blah))
(modify 1 (x 3))
(duplicate 1 (y 4))
(clear) ; Missing space in error message

(deftemplate branch
   (slot to))

(deffacts story-flow
   (branch (to obey-the-order Q9)))
   
(defrule error
   =>
   (assert (branch (to obey-the-order Q9))))
(clear) ; Erroneous constraint conflict

(defrule issue
   =>
   (bind ?values "A" "B" "C" "D" "E" "F")
   (bind ?value (nth$ 1 ?values)))
(clear) ; Erroneous constraint conflict

(defrule should-be-undefined-variable-error
   =>
   (println (implode$ ?statement)))
(clear)
