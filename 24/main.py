import sys
import operator
import itertools
from dataclasses import dataclass

import sympy as sp


THE_RANGE = set(range(1, 9 + 1))

def main():
    fname = sys.argv[1]

    # setup
    inputs = [sp.symbols(f"in{s}") for s in range(1,14 + 1)]
    iter_inputs = iter(inputs)
    vars = {
        "w": 0,
        "x": 0,
        "y": 0,
        "z": 0,
    }

    with open(fname) as f:
        for idx, l in enumerate(f.readlines()):
            print(idx + 1)
            l = l.rstrip()
            if l.startswith("#"):
                continue
            parsed = l.split()
            op, arg0, *rest = parsed
            if rest:
                arg1 = rest[0]
                try:
                    arg1 = int(arg1)
                except ValueError:
                    arg1 = vars[arg1]

            if op == "inp":
                vars[arg0] = next(iter_inputs)
            elif op == "mul":
                vars[arg0] *= arg1
            elif op == "add":
                vars[arg0] = arg1 + vars[arg0]
            elif op == "mod":
                # TODO: wtf mod is so slow?
                # TODO: fix!!!
                try:
                    if arg1 == 26 and 0 == sp.simplify(vars[arg0] -(inputs[0] + 1)):
                        continue
                except TypeError:
                    pass
                vars[arg0] %= arg1
            elif op == "div":
                # TODO: truncate towards 0
                if (arg1 == 1):
                    continue    
                vars[arg0] //= arg1
            elif op == "eql":
                lhs = vars[arg0]
                rhs = arg1

                if isinstance(vars[arg0], Branch) and isinstance(arg1, int):
                    if arg1 > 1 or arg1 < 0:
                        # TODO: bullshit
                        result = 0
                    elif arg1 == 1:
                        result = lhs
                    elif arg1 == 0:
                        result = Branch(lhs=lhs.lhs, rhs=lhs.rhs, if_false=1, if_true=0) 
                    else:
                        assert 0, "unreachable"
                else:
                    print("branch!")
                    result = Branch(lhs=lhs, rhs=rhs, if_false=0, if_true=1)

                    try:
                        print("a")
                        if 0 == sp.simplify(lhs - rhs):
                            result = 1
                        else:
                            print("x")
                            solutions = solve_discreet(lhs - rhs)
                            if solutions and (all(s not in THE_RANGE for s in solutions)):
                                result = 0
                    except TypeError as e:
                        print("AAAAA", e)

                vars[arg0] = result
            else:
                assert 0, "unreachable"

    print(vars)

@dataclass
class Branch:
    lhs: int
    rhs: int
    if_false: int
    if_true: int

    def process(a,b,op):
        return Branch(lhs=a.lhs, rhs=a.rhs, if_false=op(a.if_false,b), if_true=op(a.if_true, b))

    def __mul__(self,b):
        if b == 0:
            return 0

        return Branch.process(self, b, operator.mul)

    def __rmul__(self,b):
        return Branch.__mul__(self, b)

    def __add__(self,b):
        return self.process(b, operator.add)

    def __radd__(self,b):
        return Branch.__add__(self, b)

    def __add__(self,b):
        return self.process(b, operator.add)

    def __mod__(self,b):
        return self.process(b, operator.mod)

    def __floordiv__(self,b):
        return self.process(b, operator.floordiv)


def solve_discreet(equation):
    print(equation)
    if isinstance(equation, int):
        return set()

    varaibles = list(sorted((equation.free_symbols), key=lambda s: str(s)))

    if(len(varaibles) > 3):
        return set()

    solutions = set()

    try:
        if len(varaibles) > 1:
            s = varaibles.pop()

            for i in range(1, 9 + 1):
                new_eq = equation.subs(s, i)
                local_solutions = map(lambda t: t + (i,), solve_discreet(new_eq))
                solutions = solutions.union(local_solutions)

        else:
                sol = sp.solve(equation, set=True)[1]
                # if sol and (all(s not in THE_RANGE for s in sol)):
                    # raise ValueError("aaaa")
                return sol
    except (NotImplementedError, ValueError):
        return set()

    return solutions


if __name__ == "__main__":
    main()
