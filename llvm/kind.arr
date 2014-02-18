#lang pyret

provide *

import "llvm.arr" as LLVM

data TypeKind:
  | Void with: 
    tostring(self): "void" end
  | Half with: 
    tostring(self): "half" end
  | Float with: 
    tostring(self): "float" end
  | Double with: 
    tostring(self): "double" end
  | X86fp80 with: 
    tostring(self): "x86_fp80" end
  | Fp128 with:
    tostring(self): "fp128" end
  | Ppc_fp128 with:
    tostring(self): "ppc_fp128" end
  | Label with: 
    tostring(self): "label" end
  | Integer(width :: Number) with:
    tostring(self): "i" + self.width.tostring() end
  | FunctionType(ret :: TypeKind, params :: List<TypeKind>) with:
    tostring(self): 
      self.ret.tostring() + " (" + self.params.join-str(", ") + ")"
    end
  | Struct(fields :: List<TypeKind>, packed :: Bool)
  | Arr(len :: Number, typ :: TypeKind)
  | Pointer(typ :: TypeKind, addrspace :: Number) # Numbered address space?
  | Vector(len :: Number, typ :: TypeKind)
  | Metadata
  | X86_mmx
end

data ValueKind:
  | NullValue
  | Argument
  | BasicBlock
  | InlineAsm
  | MDNode
  | MDString
  | BlockAddress
  | ConstantAggregateZero
  | ConstantArray
  | ConstantDataArray
  | ConstantDataVector
  | ConstantExpr
  | ConstantFP
  | ConstantInt
  | ConstantPointerNull
  | ConstantStruct
  | ConstantVector
  | FunctionValue
  | GlobalAlias
  | GlobalVariable
  | UndefValue
  | Instruction(op :: LLVM.Opcode)
end
