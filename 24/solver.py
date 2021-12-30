import z3
import functools

invs = [""] + [z3.Int("in" + str(n)) for n in range(1,14 + 1)]

constrainsts = [
    invs[1] == invs[14] + 3,
    invs[2] == invs[13] + 4,
    invs[3] == invs[6] + 2,
    invs[4] == invs[5],
    invs[7] == invs[10] + 8,
    invs[8] == invs[9] - 4,
    invs[11] == invs[12] + 5,
] + [
    invs[n] >= 1 for n in range(1, 14 + 1)
] + [
    invs[n] <= 9 for n in range(1, 14 + 1)
]

total = z3.Int("total")
s = z3.Optimize()
s.add(constrainsts)

zorg = list((10 ** magnitude * invs[i] for magnitude, i in zip(reversed(range(14)), range(1, 14 + 1))))
ble = zorg[0]
for z in zorg[1:]:
    ble += z

print(ble)

s.add(total == ble)
h = s.minimize(total)
s.check()
s.lower(h)
m = s.model()

for i in range(1, 14+1):
    print(m.eval(invs[i]), end="")

print()
