Set Warnings "-notation-overridden".

Require Import Category.Lib.
Require Export Category.Theory.Functor.
Require Import Category.Structure.Terminal.
Require Export Category.Instance.Cat.

Generalizable All Variables.
Set Primitive Projections.
Set Universe Polymorphism.
Unset Transparent Obligations.
Set Implicit Arguments.

Program Instance _1 : Category := {
  ob      := unit;
  hom     := fun _ _ => unit;
  homset  := fun _ _ => {| equiv := eq |};
  id      := fun _ => tt;
  compose := fun _ _ _ _ _ => tt
}.
Next Obligation. destruct f; reflexivity. Qed.
Next Obligation. destruct f; reflexivity. Qed.

Program Instance To_1 `(C : Category) : C ⟶ _1 := {
  fobj := fun _ => tt;
  fmap := fun _ _ _ => id
}.

Program Instance Cat_Terminal : @Terminal Cat := {
  One := _1;
  one := To_1
}.
Next Obligation.
  constructive; autounfold; cat; simpl; intros;
  destruct f, g; simpl;
  rewrite ?fmap_id, ?fmap_id0;
  reflexivity.
Qed.

Program Instance Select `{C : Category} (c : C) : _1 ⟶ C := {|
  fobj := fun _ => c;
  fmap := fun _ _ _ => id
|}.
