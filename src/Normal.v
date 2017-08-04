Set Warnings "-notation-overridden".

Require Import Coq.Program.Program.
Require Import Coq.Bool.Bool.
Require Import Coq.Arith.Bool_nat.
Require Import Coq.Arith.PeanoNat.
Require Import Coq.PArith.PArith.
Require Import Coq.Lists.List.
Require Import Coq.omega.Omega.
Require Import Coq.Wellfounded.Lexicographic_Product.
Require Import Recdef.

Require Import Category.Lib.
Require Import Category.Theory.Functor.

Require Import Solver.Lib.
Require Import Solver.Expr.

Generalizable All Variables.

Section Normal.

Import EqNotations.

Inductive Arrow : Term -> Set :=
  | Here  : ∀ x y a, Arrow (Morph x y a)
  | Left  : ∀ (m : obj_idx) f g, Arrow f -> Arrow (Compose m f g)
  | Right : ∀ (m : obj_idx) f g, Arrow g -> Arrow (Compose m f g).

Definition Arrow_inv_t : forall t, Arrow t -> Type.
Proof.
  intros [] H.
  - exact False.
  - exact (H = Here x y a).
  - exact ((∃ H', H = Left m f g H') + (∃ H', H = Right m f g H')).
Defined.

Lemma Arrow_inv t f : Arrow_inv_t t f.
Proof.
  destruct f; simpl; equalities; simpl_eq; auto.
  - left. exists f0; auto.
  - right. exists f0; auto.
Defined.

Lemma Arrow_Morph `(H : Arrow (Morph x y a)) : H = Here x y a.
Proof. exact (Arrow_inv _ H). Defined.

Lemma Arrow_Compose `(H : Arrow (Compose m f g)) :
  (∃ H', H = Left m f g H') + (∃ H', H = Right m f g H').
Proof. exact (Arrow_inv _ H). Defined.

Fixpoint get_arrow `(f : Arrow t) : obj_idx * arr_idx :=
  match f with
  | Here x _ a    => (x, a)
  | Left _ _ _ x  => get_arrow x
  | Right _ _ _ x => get_arrow x
  end.

Function arrow_bequiv {t t' : Term} (p : Arrow t) (q : Arrow t') : bool :=
  match get_arrow p, get_arrow q with
  | (o, f), (o', f') => Eq_eqb o o' && Eq_eqb f f'
  end.

Lemma arrow_bequiv_eq {t t' : Term} (p : Arrow t) (q : Arrow t') :
  arrow_bequiv p q = true -> get_arrow p = get_arrow q.
Proof.
Admitted.
(*
  destruct (term_beq t t') eqn:?.
  - apply term_beq_eq in Heqb; subst; intros.
    exists eq_refl; simpl.
    generalize dependent q.
    induction p; simpl; intros; equalities.
    + pose proof (Arrow_Morph q); auto.
    + destruct (Arrow_Compose q), s; subst.
        now rewrite (IHp _ H1).
      discriminate.
    + destruct (Arrow_Compose q), s; subst.
        discriminate.
      now rewrite (IHp _ H1).
  - intros.
    rewrite arrow_beq_equation, Heqb in H.
    discriminate.
Qed.
*)

Function arrows (t : Term) : list (Arrow t) :=
  match t with
  | Identity _    => nil
  | Morph x y a   => [Here x y a]
  | Compose m f g => map (Left m f g) (arrows f) ++
                     map (Right m f g) (arrows g)
  end.

Function arrows_bequiv {t t' : Term}
         (ps : list (Arrow t)) (qs : list (Arrow t')) : bool :=
  term_beq t t' &&&
  match ps, qs with
  | nil, nil => true
  | cons p ps, cons q qs =>
    arrow_bequiv p q &&& arrows_bequiv ps qs
  | _, _ => false
  end.

(*
Fixpoint arrows_bequiv_eq {t t' : Term}
         (ps : list (Arrow t)) (qs : list (Arrow t')) :
  arrows_beq ps qs = true
    -> { H : t' = t | ps = rew [fun t => list (Arrow t)] H in qs }.
Proof.
  intros.
  rewrite arrows_beq_equation in H.
  destruct (term_beq t t') eqn:?; [|discriminate].
  apply term_beq_eq in Heqb; subst.
  exists eq_refl; simpl.
  induction ps, qs; auto; try discriminate.
  equalities.
  apply arrow_beq_eq in H0.
  destruct H0; subst; simpl; simpl_eq.
  apply arrows_beq_eq in H1.
  destruct H1.
  rewrite e.
  f_equal; clear.
  destruct t'.
  inversion a0.
Qed.
*)

(* Notation Term    := (Term arrs). *)
(* Notation TermDom := (TermDom arrs). *)
(* Notation TermCod := (TermCod arrs). *)

(* This describes the morphisms of a path, or free, category over a quiver of
   Arrows, while our environment describes a quiver (where vertices are all
   object indices, and edges are all arrow indices associated pairs of object
   indices). The denotation of an ArrowList to some category C is a forgetful
   functor from the path category over this quiver to C. Note that this
   functor is only total if the denotation of the quiver itself is total. *)
Inductive ArrowList : Set :=
  | IdentityOnly (o : obj_idx) : ArrowList
  | ArrowChain   (x y : obj_idx) (a : arr_idx) : ArrowList -> ArrowList.

Function ArrowList_beq (f g : ArrowList) : bool :=
  match f with
  | IdentityOnly o =>
    match g with
    | IdentityOnly o' => Eq_eqb o o'
    | ArrowChain _ _ _ _ => false
    end
  | ArrowChain x y f fs =>
    match g with
    | IdentityOnly _ => false
    | ArrowChain x' y' g gs =>
      Eq_eqb x x' &&& Eq_eqb y y' &&& Eq_eqb f g &&& ArrowList_beq fs gs
    end
  end.

Fixpoint ArrowList_length (x : ArrowList) : nat :=
  match x with
  | IdentityOnly _      => 0
  | ArrowChain _ _ _ xs => 1 + ArrowList_length xs
  end.

Lemma ArrowList_beq_eq (f g : ArrowList) : ArrowList_beq f g = true -> f = g.
Proof.
  apply well_founded_induction_type_2
    with (R:=symprod2 _ (ltof _ ArrowList_length)) (a:=f) (b:=g).
    apply wf_symprod2;
    apply well_founded_ltof.
  intros; destruct x, x'; simpl in H0.
  - equalities.
  - discriminate.
  - discriminate.
  - equalities.
    f_equal.
    apply H; auto.
    constructor; unfold ltof; simpl; abstract omega.
Defined.

Function ArrowList_dom (xs : ArrowList) : obj_idx :=
  match xs with
  | IdentityOnly x => x
  | ArrowChain _ _ _ xs => ArrowList_dom xs
  end.

Definition ArrowList_cod (xs : ArrowList) : obj_idx :=
  match xs with
  | IdentityOnly y => y
  | ArrowChain _ y a _ => y
  end.

(*
Inductive ForallAligned : list Arrow → Prop :=
    Align_nil : ForallAligned []
  | Align_singleton : ∀ (a : Arrow), ForallAligned [a]
  | Align_cons2 : ∀ (a b : Arrow) (l : list Arrow),
      arr_dom a = arr_cod b ->
      ForallAligned (b :: l) → ForallAligned (a :: b :: l).

Lemma ForallAligned_inv {x xs y} :
  ForallAligned (x :: y :: xs)
    -> arr_dom x = arr_cod y /\
       ForallAligned (y :: xs).
Proof.
  generalize dependent x.
  generalize dependent y.
  induction xs; intros;
  inversion H; subst; intuition.
Qed.

Lemma ForallAligned_app {x xs y ys} :
  ForallAligned (x :: xs ++ y :: ys)
    <-> ForallAligned (x :: xs) /\ ForallAligned (y :: ys) /\
        arr_cod y = arr_dom (last xs x).

Definition ListOfArrows_rect : ∀ (P : Arrow -> list Arrow → Type),
  (∀ (x : Arrow), P x []) →
  (∀ (x y : Arrow) (l : list Arrow), P y l → P x (y :: l)) →
  ∀ (x : Arrow) (l : list Arrow), P x l.
Proof.
  intros.
  generalize dependent x.
  induction l; auto.
Defined.

Definition ArrowList_append (xs ys : ArrowList) : ArrowList :=
  match xs, ys with
  | IdentityOnly f,  IdentityOnly g  => IdentityOnly g
  | IdentityOnly f,  ArrowChain g xs => ArrowChain g xs
  | ArrowChain f xs, IdentityOnly g  => ArrowChain f xs
  | ArrowChain f xs, ArrowChain g ys => ArrowChain f (xs ++ g :: ys)
  end.

Lemma ArrowList_append_chains a a0 l l0 :
  ArrowList_dom (ArrowChain a l) = ArrowList_cod (ArrowChain a0 l0) ->
  ArrowList_append (ArrowChain a l) (ArrowChain a0 l0) =
  ArrowChain a (l ++ a0 :: l0).
Proof.
  generalize dependent a0.
  generalize dependent l0.
  simpl.
  induction l using rev_ind; simpl; intros; auto.
Qed.

Lemma ArrowList_append_well_typed {dom mid cod f1 f2} :
  ArrowList_dom f1 = mid ->
  ArrowList_cod f2 = mid ->
  ArrowList_well_typed mid cod f1 ->
  ArrowList_well_typed dom mid f2 ->
    ArrowList_well_typed dom cod (ArrowList_append f1 f2).
Proof.
  generalize dependent mid.
  generalize dependent f2.
  induction f1 using ArrowList_list_rect; intros.
  - simpl in *.
    equalities; subst.
    destruct f2 using ArrowList_list_rect; simpl in *; auto.
  - simpl in *; equalities; subst.
    destruct f2.
      simpl in *; subst; intuition.
    simpl in *; equalities.
    + induction l using rev_ind.
        simpl in *; equalities.
        inversion H2; subst.
        now inversion H.
      rewrite !last_app_cons in *; simpl in *.
      replace (match l ++ [x] with
               | [] => a0
               | _ :: _ => x
               end) with x by (destruct l; auto); auto.
    + constructor; auto.
  - clear IHf1.
    equalities; subst.
    destruct f2.
      constructor; simpl in H1; intuition.
      simpl in *; subst; intuition.
    rewrite ArrowList_append_chains by congruence.
    simpl; constructor.
      simpl in H1; intuition.
    rewrite last_app_cons, last_cons.
    pose proof (ArrowList_well_typed_dom H2) as H5.
    simpl in H5.
    replace (match l ++ a :: l0 with
             | [] => a2
             | _ :: _ => last l0 a
             end) with (last l0 a) by (destruct l; auto);
    intuition; rewrite !app_comm_cons.
    apply ForallAligned_app.
    inversion H1.
    inversion H2.
    intuition.
Qed.
*)

Function ArrowList_append (xs ys : ArrowList) : ArrowList :=
  match xs with
  | IdentityOnly _ => ys
  | ArrowChain x y f fs => ArrowChain x y f (ArrowList_append fs ys)
  end.

Fixpoint normalize (p : Term) : ArrowList :=
  match p with
  | Identity x    => IdentityOnly x
  | Morph x y f   => ArrowChain x y f (IdentityOnly x)
  | Compose _ f g => ArrowList_append (normalize f) (normalize g)
  end.

Function denormalize (f : ArrowList) : Term :=
  match f with
  | IdentityOnly x => Identity x
  | ArrowChain x y f gs => Compose y (Morph x y f) (denormalize gs)
  end.

(*
Function remove_identities (t : Term) : Term :=
  match t with
  | Identity _    => t
  | Morph _ _ _   => t
  | Compose m f g =>
    match remove_identities f, remove_identities g with
    | Identity _, g => g
    | f, Identity _ => f
    | f, g => Compose m f g
    end
  end.

Function associate_composition (t : Term) : Term :=
  match t with
  | Identity _    => t
  | Morph _ _ _   => t
  | Compose m f g =>
    match remove_identities f, remove_identities g with
    | Identity _, g => g
    | f, Identity _ => f
    | f, g => Compose m f g
    end
  end.
*)

Local Obligation Tactic := intros.


Lemma normalize_denormalize {f} : normalize (denormalize f) = f.
Proof.
  induction f; simpl; auto.
  destruct (denormalize f); simpl in *;
  now rewrite IHf.
Qed.

(*
Lemma ArrowList_append_dom f g :
  ArrowList_dom f = ArrowList_cod g ->
  ArrowList_dom (ArrowList_append f g) = ArrowList_dom g.
Proof.
  destruct g, f; simpl; intros; auto.
  now rewrite last_app_cons, last_cons.
Qed.

Lemma ArrowList_append_cod f g :
  ArrowList_dom f = ArrowList_cod g ->
  ArrowList_cod (ArrowList_append f g) = ArrowList_cod f.
Proof.
  destruct f, g; simpl; intros; auto.
Qed.
*)

(*
Lemma ArrowList_normalize_dom_cod_sound {p dom cod} :
  Term_well_typed dom cod p ->
  ArrowList_dom (normalize p) = dom /\
  ArrowList_cod (normalize p) = cod.
Proof.
  generalize dependent dom.
  generalize dependent cod.
  induction p; simpl; intros; intuition; subst;
  rewrite H0 in H;
  rewrite ArrowList_append_dom ||
  rewrite ArrowList_append_cod; auto;
  specialize (IHp1 _ _ H);
  specialize (IHp2 _ _ H2);
  intuition; congruence.
Qed.

Corollary ArrowList_specific_sound p :
  Term_well_typed (TermDom p) (TermCod p) p ->
  ArrowList_dom (normalize p) = TermDom p /\
  ArrowList_cod (normalize p) = TermCod p.
Proof. apply ArrowList_normalize_dom_cod_sound. Qed.

Lemma ArrowList_well_typed_sound {f dom cod} :
  Term_well_typed dom cod f
    -> ArrowList_well_typed dom cod (normalize f).
Proof.
  generalize dependent dom.
  generalize dependent cod.
  induction f; simpl; intros; intuition.
    constructor; constructor.
  specialize (IHf1 _ _ H).
  specialize (IHf2 _ _ H2).
  pose proof (ArrowList_well_typed_dom IHf1).
  pose proof (ArrowList_well_typed_cod IHf2).
  apply (ArrowList_append_well_typed H1 H3 IHf1 IHf2).
Qed.

Set Transparent Obligations.

Theorem denormalize_well_typed dom cod f :
  ArrowList_well_typed dom cod f
    -> Term_well_typed dom cod (denormalize f).
Proof.
  destruct f; auto.
  generalize dependent a.
  generalize dependent dom.
  induction l using rev_ind; intros.
    simpl in *; intuition.
  assert (ArrowList_well_typed
            (arr_cod x) cod (ArrowChain a l)). {
    clear IHl.
    simpl in *; equalities.
    - rewrite app_comm_cons in H1.
      now apply ForallAligned_app in H1.
    - rewrite app_comm_cons in H1.
      now apply ForallAligned_app in H1.
  }
  rewrite <- ArrowList_append_chains by (simpl in *; intuition).
  specialize (IHl (arr_cod x) a H0).
  simpl in *; equalities.
  rewrite app_comm_cons in H4.
  apply ForallAligned_app in H4; equalities.
  rewrite map_app, fold_left_app; simpl.
  rewrite H4.
  intuition; subst.
  - clear -H.
    induction l using rev_ind; simpl; auto.
    rewrite map_app, fold_left_app; simpl.
    now rewrite last_rcons in *.
  - now rewrite H4 in IHl.
  - now rewrite last_rcons.
Qed.
*)

(*
Program Instance ArrowList_to_Term :
  ArrowList_Category ⟶ Term_Category := {
  fobj := fun x => x;
  fmap := fun x y f => (denormalize (`1 f); _)
}.
Next Obligation. apply denormalize_well_typed; auto. Qed.
Next Obligation.
  proper.
  simpl in *; subst.
  reflexivity.
Qed.
Next Obligation.
  erewrite !normalize_denormalize; eauto.
  pose proof (ArrowList_well_typed_dom X0).
  pose proof (ArrowList_well_typed_cod X).
  eapply ArrowList_append_well_typed; eauto.
Qed.

Fixpoint ArrowList_from_list (xs : obj_idx * list Arrow) : ArrowList :=
  match xs with
  | (x, nil) => IdentityOnly x
  | (_, x :: xs) => ArrowChain x xs
  end.

Lemma ArrowList_to_from_list xs :
  ArrowList_to_list (ArrowList_from_list xs) = xs.
Proof.
  destruct xs.
  induction l; simpl; auto.
  simpl in IHl.
  f_equal.
  destruct l; simpl in *.
    admit.
  inversion_clear IHl.
  destruct l; auto.
  f_equal.
  f_equal.
Abort.

Definition ArrowList_length (x : ArrowList) : nat :=
  match x with
  | IdentityOnly x => 0
  | ArrowChain x xs => 1 + length xs
  end.

Function ArrowList_beqn (n : nat) (x y : ArrowList) : bool :=
  match n with
  | O => true
  | S n' =>
    match x, y with
    | IdentityOnly cod1, IdentityOnly cod2 => Eq_eqb cod1 cod2
    | ArrowChain x1 nil, ArrowChain x2 (_ :: _) =>
      match n' with
      | O => Eq_eqb x1 x2
      | S x => false
      end
    | ArrowChain x1 (_ :: _), ArrowChain x2 nil =>
      match n' with
      | O => Eq_eqb x1 x2
      | S x => false
      end
    | ArrowChain x1 (y1 :: ys1), ArrowChain x2 (y2 :: ys2) =>
      Eq_eqb x1 x2 &&&
      ArrowList_beqn n' (ArrowChain y1 ys1) (ArrowChain y2 ys2)
    | _, _ => false
    end
  end.

Function ArrowList_drop (n : nat) (xs : ArrowList) : ArrowList :=
  match n with
  | O => xs
  | S n' =>
    match xs with
    | IdentityOnly o => IdentityOnly o
    | ArrowChain f nil => IdentityOnly (arr_cod f)
    | ArrowChain f (x :: xs) => ArrowList_drop n' (ArrowChain x xs)
    end
  end.
*)

End Normal.
