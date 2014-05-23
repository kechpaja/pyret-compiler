#lang pyret

fun f() -> ( -> Number):
  x = 8
  fun g() -> Number:
    x
  end
  g
end

h = f()
print(h())
