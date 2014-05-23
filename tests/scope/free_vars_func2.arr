#lang pyret

fun f() -> ( -> Number):
  x = 8
  fun g() -> ( -> ( -> Number)):
    fun h() -> ( -> Number):
      fun i() -> Number:
        x
      end
      i
    end
    h
  end
  g()()
end

ii = f()
print(ii())
