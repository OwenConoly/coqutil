Require Import bedrock2.Syntax bedrock2.NotationsCustomEntry.

Import Syntax.Coercions BinInt String List.ListNotations.
Local Open Scope string_scope. Local Open Scope Z_scope. Local Open Scope list_scope.

Definition stacktrivial : bedrock_func := let t := "t" in
  ("stacktrivial", ([]:list String.string, [], bedrock_func_body:(stackalloc 4 as t; /*skip*/ ))).

Definition stacknondet : bedrock_func := let a := "a" in let b := "b" in let t := "t" in
  ("stacknondet", ([]:list String.string, [a; b], bedrock_func_body:(stackalloc 4 as t;
  a = (load4(t) >> coq:(8));
  store1(a+coq:(3), coq:(42));
  b = (load4(t) >> coq:(8))
))).

Definition stackdisj : bedrock_func := let a := "a" in let b := "b" in
  ("stackdisj", ([]:list String.string, [a; b], bedrock_func_body:(
  stackalloc 4 as a;
  stackalloc 4 as b;
  /*skip*/
))).

Require bedrock2.WeakestPrecondition.
Require Import bedrock2.Semantics bedrock2.FE310CSemantics.
Require Import coqutil.Map.Interface bedrock2.Map.Separation bedrock2.Map.SeparationLogic.

Require bedrock2.WeakestPreconditionProperties.
From coqutil.Tactics Require Import letexists eabstract.
Require Import bedrock2.ProgramLogic bedrock2.Scalars.
Require Import coqutil.Word.Interface.

Section WithParameters.
  Context {word: word.word 32} {mem: map.map word Byte.byte}.
  Context {word_ok: word.ok word} {mem_ok: map.ok mem}.

  Instance spec_of_stacktrivial : spec_of "stacktrivial" := fun functions => forall m t,
      WeakestPrecondition.call functions
        "stacktrivial" t m [] (fun t' m' rets => rets = [] /\ m'=m /\ t'=t).

  Lemma stacktrivial_ok : program_logic_goal_for_function! stacktrivial.
  Proof.
    repeat straightline.

    set (R := eq m).
    pose proof (eq_refl : R m) as Hm.

    repeat straightline.

    (* test for presence of intermediate separation logic hypothesis generated by [straightline_stackalloc] *)
    lazymatch goal with H : Z.of_nat (Datatypes.length ?stackarray) = 4 |- _ =>
    lazymatch goal with H : sep _ _ _ |- _ =>
    lazymatch type of H with context [Array.array ptsto _ ?a stackarray] =>
    idtac
    end end end.

    intuition congruence.
  Qed.

  Instance spec_of_stacknondet : spec_of "stacknondet" := fun functions => forall m t,
      WeakestPrecondition.call functions
        "stacknondet" t m [] (fun t' m' rets => exists a b, rets = [a;b] /\ a = b /\ m'=m/\t'=t).

  Require Import bedrock2.string2ident.

  Lemma stacknondet_ok : program_logic_goal_for_function! stacknondet.
  Proof.
    repeat straightline.
    set (R := eq m).
    pose proof (eq_refl : R m) as Hm.
    repeat straightline.
    assert (sep R (scalar32 a (Interface.word.of_Z (LittleEndian.combine _ (HList.tuple.of_list stack)))) m)
      by admit.
    repeat straightline.
  Abort.

  Instance spec_of_stackdisj : spec_of "stackdisj" := fun functions => forall m t,
      WeakestPrecondition.call functions
        "stackdisj" t m [] (fun t' m' rets => exists a b, rets = [a;b] /\ a <> b /\ m'=m/\t'=t).

  Lemma stackdisj_ok : program_logic_goal_for_function! stackdisj.
  Proof.
    repeat straightline.
    set (R := eq m).
    pose proof (eq_refl : R m) as Hm.
    repeat straightline.
    repeat esplit.
    all : try intuition congruence.
    match goal with |- _ <> _ => idtac end.
  Abort.


  From bedrock2 Require Import ToCString Bytedump.
  Local Open Scope bytedump_scope.
  Goal True.
    let c_code := eval cbv in (byte_list_of_string (c_module (stacknondet::nil))) in
    idtac c_code.
  Abort.
End WithParameters.
