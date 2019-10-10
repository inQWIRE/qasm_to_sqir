Require Import List.
Require Import String.

Require Import Map.
Require Import Sets.

Set Implicit Arguments.

Notation Id := string. (* Identifier x *)
Definition Id_eq : forall x y : Id, {x=y} + {x<>y} := string_dec.
Infix "==id" := Id_eq (no associativity, at level 50).

Notation Idx := nat. (* Index i *)

Inductive E : Set := (* Expression *)
| e_bit (x:Id)
| e_reg (x:Id) (I:Idx).

(* purely unitary effects *)
Inductive U : Set := (* Unitary Stmt *)
| u_cx (E1 E2:E)
| u_h (E:E)
| u_t (E:E)
| u_tdg (E:E)
| u_app (Eg:E) (_:list E) (* Eg is unitary gate or named circuit *)
| u_seq (U1 U2:U).

(* also includes non-unitary *)
Inductive C : Set := (* Command *)
| c_creg (x:Id) (I:Idx)
| c_qreg (x:Id) (I:Idx)
| c_gate (x:Id) (_:list Id) (U:U) (* declare unitary circuits *)
| c_measure (E1 E2:E)
| c_reset (E:E)
| c_U (U:U)
| c_if (E:E) (I:Idx) (U:U) (* only tests a classical bit *)
| c_seq (C1 C2:C).

Notation L := nat. (* Location l *)

Inductive V : Set := (* Value *)
| v_loc (l:L)
| v_arr (ls:list L)
| v_circ (xs:list Id) (U:U). (* unitary circuits *)

Inductive S : Set :=
| s_E (E:E)
| s_U (U:U)
| s_C (C:C).

Definition Env := fmap Id V. (* sigma *)

(* Classical bits *)
Parameter c0 : Type.
Parameter c1 : Type.

Definition Heap := fmap L (c0+c1). (* eta *)

(* Qubit abstract type *)
Parameter Qbit : Type.

Definition QState := fmap L Qbit.

(* Built-in gates, TODO: fix dummy definitions *)
Definition H (l:L) (qs:QState) : QState := qs.
Definition T (l:L) (qs:QState) : QState := qs.
Definition Tdg (l:L) (qs:QState) : QState := qs.
Definition CNOT (l1 l2:L) (qs:QState) : QState := qs.

(* Big-step operational semantics *)

(* Expressions *)
Inductive Eeval : E * Env * Heap * QState -> option V -> Prop :=
| EvalVar : forall x env heap st,
    x \in dom env
    -> Eeval (e_bit x, env, heap, st) (env $? x)
| EvalReg : forall x I env heap st ls,
    Eeval (e_bit x, env, heap, st) (Some (v_arr ls))
    -> I <= (List.length ls)
    -> Eeval (e_reg x I, env, heap, st) (Some (v_loc (nth I ls 0))).

(* Unitary statements *)
Inductive Ueval : U * Env * Heap * QState -> QState -> Prop :=
| EvalH : forall E env heap st l,
    Eeval (E, env, heap, st) (Some (v_loc l))
    -> Ueval (u_h E, env, heap, st) (H l st)
| EvalT : forall E env heap st l,
    Eeval (E, env, heap, st) (Some (v_loc l))
    -> Ueval (u_t E, env, heap, st) (T l st)
| EvalTdg : forall E env heap st l,
    Eeval (E, env, heap, st) (Some (v_loc l))
    -> Ueval (u_tdg E, env, heap, st) (Tdg l st)
| EvalCnot : forall E1 E2 env heap st l1 l2,
    Eeval (E1, env, heap, st) (Some (v_loc l1))
    -> Eeval (E2, env, heap, st) (Some (v_loc l2))
    -> Ueval (u_cx E1 E2, env, heap, st) (CNOT l1 l2 st)
| EvalApp : forall E env heap st xs U Es st',
    Eeval (E, env, heap, st) (Some (v_circ xs U))
    -> Ueval (U, env, heap, st) st' (* TODO need to do subst es/xs,
                                        WAIT, do I need to even do that? *)
    -> Ueval (u_app E Es, env, heap, st) st'
| EvalUSeq : forall U1 U2 env heap st st' st'',
    Ueval (U1, env, heap, st) st'
    -> Ueval (U2, env, heap, st') st''
    -> Ueval (u_seq U1 U2, env, heap, st) st''.

(* Commands *)
Inductive Ceval : C * Env * Heap * QState -> Env * Heap * QState -> Prop :=
| EvalCreg : forall x I ls env heap st,
    (* TODO check freshness for ls *)
  Ceval (c_creg x I, env, heap, st) (env $+ (x, v_arr ls), heap, st)
| EvalQreg : forall x I ls env heap st,
    (* TODO check freshness for ls *)
    Ceval (c_qreg x I, env, heap, st) (env $+ (x, v_arr ls), heap, st)
| EvalGate : forall x xs U env heap st,
  Ceval (c_gate x xs U, env, heap, st) (env $+ (x, v_circ xs U), heap, st)
| EvalCSeq : forall C1 C2 e e' e'' h h' h'' st st' st'',
    Ceval (C1, e, h, st) (e', h', st')
    -> Ceval (C2, e', h', st') (e'', h'', st'')
    -> Ceval (c_seq C1 C2, e, h, st) (e'', h'', st'').
