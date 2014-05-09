#lang pyret

provide *

import ast as A

data Type:
  | t-blank
  | t-any
  | t-name(name :: String)
  | t-arrow(args :: List<Type>, ret :: Type)
  | t-method(args :: List<Type>, ret :: Type)
  | t-record(fields :: List<TypeField>)
  | t-void
  | t-byte
  | t-word
  | t-number
  | t-pointer(ty :: Type)
  | t-param-name(name :: String, param :: Type)
sharing:
  tostring(self):
    cases(Type) self:
      | t-blank =>
        "Blank type"
      | t-any =>
        "Any"
      | t-name(name) =>
        name
      | t-arrow(args, ret) =>
        args.join-str(", ") + " -> " + ret.tostring()
      | t-method(args, ret) =>
        "((" + args.join-str(", ") + ") -> " + ret.tostring() + ")"
      | t-record(fields) =>
      | t-void =>
        "Void"
      | t-byte =>
        "Byte"
      | t-word =>
        "Word"
      | t-number =>
        "Number"
      | t-pointer(ty) =>
        ty.tostring() + "*"
      | t-param-name(name, param) =>
    end
  end,
  is-composite(self):
    cases (Type) self:
      | t-arrow(_, _) => true
      | t-method(_, _) => true
      | t-record(_) => true
      | t-pointer(_) => true
      | else => false
    end
  end
end

data TypeField:
  | t-field(name :: String, type :: Type)
end

fun ann-to-type(a :: A.Ann) -> Type:
  cases(A.Ann) a:
    | a_blank =>
      t-blank
    | a_any =>
      t-any
    | a_name(l, id) =>
      if id == "Number":
        t-number
      else:
        t-name(id)
      end
    | a_arrow(l, args, ret) =>
      t-arrow(args.map(ann-to-type), ann-to-type(ret))
    | a_method(l, args, ret) =>
      t-method(args.map(ann-to-type), ann-to-type(ret))
    | a_record(l, fields) =>
      t-record(fields.map(afield-to-tfield))
    | a_app(l, ann, args) =>
      raise("a_app not supported")
    | a_pred(l, ann, exp) =>
      raise("a_pred not supported")
    | a_dot(l, obj, field) =>
      raise("a_dot not supported")
  end
end

fun afield-to-tfield(field :: A.AField):
  cases(A.AField) field:
    | a_field(l, name, ann) =>
      t-field(name, ann-to-type(ann))
  end
end
