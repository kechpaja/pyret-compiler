#lang pyret

provide *
import ast as A
import "ast-common.arr" as AC
import pprint as PP

INDENT = 2

break-one = PP.break(1)
str-method = PP.str(" method")
str-letrec = PP.str("letrec ")
str-period = PP.str(".")
str-bang = PP.str("!")
str-colon = PP.str(":")
str-colonspace = PP.str(":")
str-end = PP.str("end")
str-let = PP.str("let ")
str-var = PP.str("var ")
str-if = PP.str("if ")
str-elsecolon = PP.str("else:")
str-try = PP.str("try:")
str-except = PP.str("except")
str-spacecolonequal = PP.str(" :=")
str-spaceequal = PP.str(" =")

dummy-loc = error.location("dummy-location", -1, -1)

Loc = error.Location

data AProg:
  | a-program(l :: Loc, imports :: List<AHeader>, body :: AExpr) with:
    label(self): "a-program" end,
    tosource(self):
      PP.group(
        PP.flow_map(PP.hardline, fun(i): i.tosource() end, self.imports)
          + PP.hardline
          + self.body.tosource()
        )
    end
sharing:
  visit(self, visitor):
    self._match(visitor, fun(): raise("No visitor field for " + self.label()) end)
  end
end

data AHeader:
  | a-import-file(l :: Loc, file :: String, name :: String) with:
    label(self): "a-import-file" end
  | a-import-builtin(l :: Loc, lib :: String, name :: String) with:
    label(self): "a-import-builtin" end
  | a-provide(l :: Loc, val :: AExpr) with:
    label(self): "a-import-provide" end
sharing:
  visit(self, visitor):
    self._match(visitor, fun(): raise("No visitor field for " + self.label()) end)
  end
end

data ACasesBranch:
  | a-cases-branch(l :: Loc, name :: String, args :: List<AC.Bind>, body :: AExpr)
end

data AExpr:
  | a-let(l :: Loc, bind :: AC.Bind, e :: ALettable, body :: AExpr) with:
    label(self): "a-let" end,
    tosource(self):
      PP.soft-surround(INDENT, 1,
        str-let + break-one + self.bind.tosource() + str-spaceequal + self.e.tosource() + str-colon,
        self.body.tosource(),
        str-end)
    end
  | a-var(l :: Loc, bind :: AC.Bind, e :: ALettable, body :: AExpr) with:
    label(self): "a-var" end,
    tosource(self):
      PP.soft-surround(INDENT, 1,
        str-var + break-one + self.bind.tosource() + str-spaceequal + self.e.tosource() + str-colon,
        self.body.tosource(),
        str-end)
    end
  | a-try(l :: Loc, body :: AExpr, b :: AC.Bind, _except :: AExpr) with:
    label(self): "a-try" end,
    tosource(self):
      _try = str-try + break-one
        + PP.nest(INDENT, self.body.tosource()) + break-one
      _except = str-except + PP.parens(self.b.tosource()) + str-colon + break-one
        + PP.nest(INDENT, self._except.tosource()) + break-one
      PP.group(_try + _except + str-end)
    end
  | a-split-app(l :: Loc, is-var :: Boolean, f :: AVal, args :: List<AVal>, helper :: String, helper-args :: List<AVal>) with:
    label(self): "a-split-app" end,
    tosource(self):
      PP.group(self.f.tosource()
          + PP.parens(PP.nest(INDENT,
            PP.separate(PP.commabreak, self.args.map(fun(f): f.tosource() end))))) +
        PP.str("and then... ") +
      PP.group(PP.str(self.helper) +
          PP.parens(PP.nest(INDENT,
            PP.separate(PP.commabreak, self.helper-args.map(fun(f): f.tosource() end)))))
    end
  | a-if(l :: Loc, c :: AVal, t :: AExpr, e :: AExpr) with:
    label(self): "a-if" end,
    tosource(self):
      str-if + break-one + self.c.tosource() + str-colon +
          PP.nest(INDENT, break-one + self.t.tosource()) +
        str-elsecolon
          PP.nest(INDENT, break-one + self.e.tosource())
    end
  | a-cases(l :: Loc,
            type :: A.Ann,
            val :: AVal,
            branches :: List<ACasesBranch>,
            _else :: Option<AExpr>) with:
    label(self): "a-cases" end,
    tosource(self):
      raise("a-cases.tosource() not implemented")
    end
  | a-lettable(e :: ALettable) with:
    label(self): "a-lettable" end,
    tosource(self):
      self.e.tosource()
    end
sharing:
  visit(self, visitor):
    self._match(visitor, fun(): raise("No visitor field for " + self.label()) end)
  end
end

data AVariant:
  | a-variant(
      l :: Loc,
      name :: String,
      members :: List<AVariantMember>,
      with-members :: List<AField>
    ) with:
    label(self): "a-variant" end,
    tosource(self): PP.str("a-variant") end
  | a-singleton-variant(
      l :: Loc,
      name :: String,
      with-members :: List<AField>
    ) with:
    label(self): "a-variant" end,
    tosource(self): PP.str("a-variant") end
end

data AMemberType:
  | a-normal with:
    label(self): "a-normal" end,
    tosource(self): PP.str("") end
  | a-cyclic with:
    label(self): "a-cyclic" end,
    tosource(self): PP.str("cyclic ") end
  | a-mutable with:
    label(self): "a-mutable" end,
    tosource(self): PP.str("mutable ") end
end

data AVariantMember:
  | a-variant-member(
      l :: Loc,
      member-type :: AMemberType,
      bind :: AC.Bind
    ) with:
    label(self): "a-variant-member" end,
    tosource(self):
      self.member_type.tosource() + self.bind.tosource()
    end
sharing:
  visit(self, visitor):
    self._match(visitor, fun(): raise("No visitor field for " + self.label()) end)
  end
end


data ALettable:
  | a-data-expr(l :: Loc, name :: String, variants :: List<AVariant>, shared :: List<AField>) with:
    label(self): "a-data-expr" end,
    tosource(self):
      PP.str("data-expr")
    end
  | a-assign(l :: Loc, id :: String, value :: AVal) with:
    label(self): "a-assign" end,
    tosource(self):
      PP.nest(INDENT, PP.str(self.id) + str-spacecolonequal + break-one + self.value.tosource())
    end
  | a-app(l :: Loc, _fun :: AVal, args :: List<AVal>) with:
    label(self): "a-app" end,
    tosource(self):
      PP.group(self._fun.tosource()
          + PP.parens(PP.nest(INDENT,
            PP.separate(PP.commabreak, self.args.map(fun(f): f.tosource() end)))))
    end
  | a-help-app(l :: Loc, f :: String, args :: List<AVal>) with:
    label(self): "a-help-app" end,
    tosource(self):
      PP.group(PP.str(self.f) +
          PP.parens(PP.nest(INDENT,
            PP.separate(PP.commabreak, self.args.map(fun(f): f.tosource() end)))))
    end
  | a-obj(l :: Loc, fields :: List<AField>) with:
    label(self): "a-obj" end,
    tosource(self):
      PP.surround-separate(INDENT, 1, PP.lbrace + PP.rbrace,
        PP.lbrace, PP.commabreak, PP.rbrace, self.fields.map(fun(f): f.tosource() end))
    end
  | a-update(l :: Loc, super :: AVal, fields :: List<AField>) with:
    label(self): "a-update" end,
    tosource(self):
      PP.str("update")
    end
  | a-extend(l :: Loc, super :: AVal, fields :: List<AField>) with:
    label(self): "a-extend" end,
    tosource(self):
      PP.str("extend")
    end
  | a-dot(l :: Loc, obj :: AVal, field :: String) with:
    label(self): "a-dot" end,
    tosource(self): PP.infix(INDENT, 0, str-period, self.obj.tosource(), PP.str(self.field)) end
  | a-colon(l :: Loc, obj :: AVal, field :: String) with:
    label(self): "a-colon" end,
    tosource(self): PP.infix(INDENT, 0, str-colon, self.obj.tosource(), PP.str(self.field)) end
  | a-get-bang(l :: Loc, obj :: AVal, field :: String) with:
    label(self): "a-get-bang" end,
    tosource(self): PP.infix(INDENT, 0, str-bang, self.obj.tosource(), PP.str(self.field)) end
    # TODO I (kechpaja) added "ret" so that we can type-check the return value
  | a-lam(l :: Loc, args :: List<AC.Bind>, ret :: A.Ann, body :: AExpr) with:
    label(self): "a-lam" end,
    tosource(self): fun-method-pretty(PP.str("lam"), self.args, self.body) end
  | a-method(l :: Loc, args :: List<AC.Bind>, ret :: A.Ann, body :: AExpr) with:
    label(self): "a-method" end,
    tosource(self): fun-method-pretty(PP.str("method"), self.args, self.body) end
  | a-val(v :: AVal) with:
    label(self): "a-val" end,
    tosource(self): self.v.tosource() end
sharing:
  visit(self, visitor):
    self._match(visitor, fun(): raise("No visitor field for " + self.label()) end)
  end
end

fun fun-method-pretty(typ, args, body):
  arg-list = PP.nest(INDENT,
    PP.surround-separate(INDENT, 0, PP.lparen + PP.rparen, PP.lparen, PP.commabreak, PP.rparen,
      args.map(fun(a): a.tosource() end)))
  header = PP.group(typ + arg-list + str-colon)
  PP.surround(INDENT, 1, header, body.tosource(), str-end)
end

data AField:
  | a-field(l :: Loc, name :: String, value :: AVal) with:
    label(self): "a-field" end,
    tosource(self): PP.nest(INDENT, PP.str(self.name) + str-colonspace + self.value.tosource()) end,
sharing:
  visit(self, visitor):
    self._match(visitor, fun(): raise("No visitor field for " + self.label()) end)
  end
end

data AVal:
  | a-num(l :: Loc, n :: Number) with:
    label(self): "a-num" end,
    tosource(self): PP.number(self.n) end
  | a-str(l :: Loc, s :: String) with:
    label(self): "a-str" end,
    tosource(self): PP.squote(PP.str(self.s)) end
  | a-bool(l :: Loc, b :: Bool) with:
    label(self): "a-bool" end,
    tosource(self): PP.str(self.b.tostring()) end
  # used for letrec
  | a-undefined(l :: Loc) with:
    label(self): "a-undefined" end,
    tosource(self): PP.str("UNDEFINED") end
  | a-id(l :: Loc, id :: String) with:
    label(self): "a-id" end,
    tosource(self): PP.str(self.id) end
  | a-id-var(l :: Loc, id :: String) with:
    label(self): "a-id-var" end,
    tosource(self): PP.str("!" + self.id) end
  | a-id-letrec(l :: Loc, id :: String) with:
    label(self): "a-id-letrec" end,
    tosource(self): PP.str("~" + self.id) end
sharing:
  visit(self, visitor):
    self._match(visitor, fun(): raise("No visitor field for " + self.label()) end)
  end
end

fun strip-loc-prog(p :: AProg):
  cases(AProg) p:
    | a-program(_, imports, body) =>
      a-program(dummy-loc, imports.map(strip-loc-header), body^strip-loc-expr())
  end
end

fun strip-loc-header(h :: AHeader):
  cases(AHeader) h:
    | a-import-builtin(_, name, id) => a-import-builtin(dummy-loc, name, id)
    | a-import-file(_, file, id) => a-import-builtin(dummy-loc, file, id)
    | a-provide(_, val) => a-provide(dummy-loc, val)
  end
end

fun strip-loc-expr(expr :: AExpr):
  cases(AExpr) expr:
    | a-let(_, bind, val, body) =>
      a-let(dummy-loc, bind^strip-loc-bind(), val^strip-loc-lettable(), body^strip-loc-expr())
    | a-var(_, bind, val, body) =>
      a-var(dummy-loc, bind^strip-loc-bind(), val^strip-loc-lettable(), body^strip-loc-expr())
    | a-try(_, body, bind, _except) =>
      a-try(dummy-loc, body^strip-loc-expr(), bind^strip-loc-bind(), _except^strip-loc-expr())
    | a-if(_, c, t, e) =>
      a-if(dummy-loc, c^strip-loc-val(), t^strip-loc-expr(), e^strip-loc-expr())
    | a-split-app(_, is-var, f, args, helper, helper-args) =>
      a-split-app(
          dummy-loc,
          is-var,
          f^strip-loc-val(),
          args.map(strip-loc-val),
          helper,
          helper-args.map(strip-loc-val)
        )
    | a-lettable(e) =>
      a-lettable(e^strip-loc-lettable())
  end
end

fun strip-loc-bind(bind :: AC.Bind):
  cases(AC.Bind) bind:
    | c-bind-loc(_, id, ann) => AC.c-bind(id, ann)
  end
end

fun strip-loc-lettable(lettable :: ALettable):
  cases(ALettable) lettable:
    | a-assign(_, id, value) => a-assign(dummy-loc, id, value^strip-loc-val())
    | a-app(_, f, args) =>
      a-app(dummy-loc, f^strip-loc-val(), args.map(strip-loc-val))
    | a-help-app(_, f, args) =>
      a-help-app(dummy-loc, f, args.map(strip-loc-val))
    | a-obj(_, fields) => a-obj(dummy-loc, fields.map(strip-loc-field))
    | a-update(_, super, fields) =>
      a-update(_, super^strip-loc-val(), fields.map(strip-loc-field))
    | a-extend(_, super, fields) =>
      a-extend(_, super^strip-loc-val(), fields.map(strip-loc-field))
    | a-dot(_, obj, field) =>
      a-dot(dummy-loc, obj^strip-loc-val(), field)
    | a-colon(_, obj, field) =>
      a-colon(dummy-loc, obj^strip-loc-val(), field)
    | a-get-bang(_, obj, field) =>
      a-get-bang(dummy-loc, obj^strip-loc-val(), field)
    | a-lam(_, args, body) =>
      a-lam(dummy-loc, args, body^strip-loc-expr())
    | a-method(_, args, body) =>
      a-method(dummy-loc, args, body^strip-loc-expr())
    | a-val(v) =>
      a-val(v^strip-loc-val())
  end
end

fun strip-loc-field(field :: AField):
  cases(AField) field:
    | a-field(_, name, value) => a-field(dummy-loc, name, value^strip-loc-val())
  end
end

fun strip-loc-val(val :: AVal):
  cases(AVal) val:
    | a-num(_, n) => a-num(dummy-loc, n)
    | a-str(_, s) => a-str(dummy-loc, s)
    | a-bool(_, b) => a-bool(dummy-loc, b)
    | a-undefined(_) => a-undefined(dummy-loc)
    | a-id(_, id) => a-id(dummy-loc, id)
    | a-id-var(_, id) => a-id-var(dummy-loc, id)
    | a-id-letrec(_, id) => a-id-letrec(dummy-loc, id)
  end
end

default-map-visitor = {
  a-program(self, l :: Loc, imports :: List<AHeader>, body :: AExpr):
    a-program(l, imports.map(_.visit(self)), body.visit(self))
  end,
  a-import-file(self, l :: Loc, file :: String, name :: String):
    a-import-file(l, file, name)
  end,
  a-import-builtin(self, l :: Loc, lib :: String, name :: String):
    a-import-builtin(l, lib, name)
  end,
  a-provide(self, l :: Loc, val :: AExpr):
    a-provide(l, val.visit(self))
  end,
  a-let(self, l :: Loc, bind :: AC.Bind, e :: ALettable, body :: AExpr):
    a-let(l, bind.visit(self), e.visit(self), body.visit(self))
  end,
  a-var(self, l :: Loc, bind :: AC.Bind, e :: ALettable, body :: AExpr):
    a-var(l, bind.visit(self), e.visit(self), body.visit(self))
  end,
  a-try(self, l :: Loc, body :: AExpr, b :: AC.Bind, _except :: AExpr):
    a-try(self, l, body.visit(self), b.visit(self), _except.visit(self))
  end,
  a-split-app(self, l :: Loc, is-var :: Boolean, f :: AVal, args :: List<AVal>, helper :: String, helper-args :: List<AVal>):
    a-split-app(self, l, is-var, f.visit(self), args.map(_.visit(self)), helper, helper-args.map(_.visit(self)))
  end,
  a-if(self, l :: Loc, c :: AVal, t :: AExpr, e :: AExpr):
    a-if(l, c.visit(self), t.visit(self), e.visit(self))
  end,
  a-lettable(self, e :: ALettable):
    a-lettable(e.visit(self))
  end,
  a-assign(self, l :: Loc, id :: String, value :: AVal):
    a-assign(l, id, value.visit(self))
  end,
  a-app(self, l :: Loc, _fun :: AVal, args :: List<AVal>):
    a-app(l, _fun.visit(self), args.map(_.visit(self)))
  end,
  a-help-app(self, l :: Loc, f :: String, args :: List<AVal>):
    a-help-app(self, l, f, args.map(_.visit(self)))
  end,
  a-obj(self, l :: Loc, fields :: List<AField>):
    a-obj(self, l, fields.map(_.visit(self)))
  end,
  a-update(self, l :: Loc, super :: AVal, fields :: List<AField>):
    a-update(l, super.visit(self), fields.map(_.visit(self)))
  end,
  a-extend(self, l :: Loc, super :: AVal, fields :: List<AField>):
    a-extend(l, super.visit(self), fields.map(_.visit(self)))
  end,
  a-dot(self, l :: Loc, obj :: AVal, field :: String):
    a-dot(l, obj.visit(self), field)
  end,
  a-colon(self, l :: Loc, obj :: AVal, field :: String):
    a-colon(l, obj.visit(self), field)
  end,
  a-get-bang(self, l :: Loc, obj :: AVal, field :: String):
    a-get-bang(l, obj.visit(self), field)
  end,
  a-lam(self, l :: Loc, args :: List<AC.Bind>, body :: AExpr):
    a-lam(l, args.map(_.visit(self)), body.visit(self))
  end,
  a-method(self, l :: Loc, args :: List<AC.Bind>, body :: AExpr):
    a-method(l, args.map(_.visit(self)), body.visit(self))
  end,
  a-val(self, v :: AVal):
    a-val(v.visit(self))
  end,
  a-field(self, l :: Loc, name :: String, value :: AVal):
    a-field(l, name, value.visit(self))
  end,
  a-num(self, l :: Loc, n :: Number):
    a-num(l, n)
  end,
  a-str(self, l :: Loc, s :: String):
    a-str(l, s)
  end,
  a-bool(self, l :: Loc, b :: Bool):
    a-bool(l, b)
  end,
  a-undefined(self, l :: Loc):
    a-undefined(l)
  end,
  a-id(self, l :: Loc, id :: String):
    a-id(id)
  end,
  a-id-var(self, l :: Loc, id :: String):
    a-id-var(id)
  end,
  a-id-letrec(self, l :: Loc, id :: String):
    a-id-letrec(id)
  end
}
