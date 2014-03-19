#lang pyret

provide *

import "llvm/llvm.arr" as L
import "llvm/kind.arr" as K
import "ast-anf.arr" as AN

data Int:
 | IntS(s :: String)
end

data AccessPath: 
  | OffP(i :: Int)
  | SelP(i :: Int, a :: AccessPath)
end

data VariantMember: 
  | l-variant-member(name :: String, type :: ConRep)
end

data Variant:
  | l-variant(name :: String, tag :: Int, fields :: List<VariantMember>)
end

data ADT:
  | l-adt(variants :: Variant)
sharing:
  lookup-variant(self, needle-name):
    cases(ADT) self:
      | l-adt(haystack) => 
        needle = list.find(fun(variant):
          cases(Variant) variant:
            | l-variant(name, tag, fields) => name == needle-name
          end
        end, haystack)
        cases(Option<ADT>) needle:
          | some(adt) => adt
          | none => 
            raise("Variant " + needle-name + " does not exist! Bugs may exist in compiler.")
        end
    end
  end
end

data Global:
  | l-number(id :: String, n :: String)
  | l-string(id :: String, s :: String)
end

data ConRep:
  | Undecided
  | Tagged(variant :: Int)
  | Constant(variant :: Int)
  | Transparent
  | TransU
  | TransB
  | Ref
  | Variable(id :: String, ap :: AccessPath)
  | VariableC(id :: String, ap :: AccessPath)
sharing:
  toint(self) -> Int:
    cases(ConRep) self:
      | Undecided                 => raise("This ConRep not implemented yet")
      | Tagged(variant :: Int)    => variant
      | Constant(variant :: Int)  => variant
      | Transparent               => raise("This ConRep not implemented yet")
      | TransU                    => raise("This ConRep not implemented yet")
      | TransB                    => raise("This ConRep not implemented yet")
      | Ref                       => raise("This ConRep not implemented yet")
      | Variable(_, _)            => raise("This ConRep not implemented yet")
      | VariableC(_, _)           => raise("This ConRep not implemented yet")
    end
  end,
  totype(self) -> K.TypeKind:
    word = K.Integer(64)
    cases(ConRep) self:
      | Undecided                 => raise("This ConRep not implemented yet")
      | Tagged(_)    => 
        K.Struct([K.TypeField("tag", word), K.TypeField("value", word)], false)
      | Constant(_)  => word
      | Transparent               => raise("This ConRep not implemented yet")
      | TransU                    => raise("This ConRep not implemented yet")
      | TransB                    => raise("This ConRep not implemented yet")
      | Ref                       => raise("This ConRep not implemented yet")
      | Variable(_, _)            => raise("This ConRep not implemented yet")
      | VariableC(_, _)           => raise("This ConRep not implemented yet")
    end
  end
end

data Program:
  | l-prog(constants :: List<Global>, procs :: List<Procedure>, adts :: List<ADT>)
end

data Bind:
    l-bind(id :: String, ann :: AN.ABind)
end

data Procedure:
    l-proc(name :: String, args :: List<AN.ABind>, ret :: AN.Ann, body :: Expression)
end

data Lettable:
  | l-application(f :: String, args :: List<String>)
  | l-select(field :: Number, id :: String, rep :: ConRep)
end

data Branch:
  | l-branch(constructor :: ConRep, code :: List<L.OpCode>)
end

data Expression:
  | l-switch(value :: String, branches :: List<Branch>, default :: Option<Expression>)
  | l-let(binding :: AN.ABind, e :: Lettable, body :: Expression)
  | l-assign(binding :: String, e :: Lettable)
  | l-if(cond :: String, consq :: Expression, altern :: Expression)
end

