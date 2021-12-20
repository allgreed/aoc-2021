from functools import reduce
from itertools import product

def bits(s): return [int(c == '#') for c in s.strip()]
def gen(Y, X):
    for y in range(Y-1, Y+2):
        for x in range(X-1, X+2): yield y, x

f = open('real.txt')
alg = bits(f.readline())
f.readline()
img = [bits(l) for l in f.readlines()]
init_len = len(img)
I = dict(((y, x),img[y][x]) for x, y in product(range(init_len), repeat=2))

for iteration in range(50):
    m = -iteration
    M = init_len + iteration
    border = [(m-1, x) for x in range(m-1, M+1)] +\
             [(M, x) for x in range(m-1, M+1)] +\
             [(y, m-1) for y in range(m-1, M+1)] +\
             [(y, M) for y in range(m-1, M+1)]
    I.update(dict([(c, (iteration%2)*alg[0]) for c in border]))
    I = dict([(coord, alg[reduce(lambda a,b: (a<<1)|b, [I.get(c, (iteration%2)*alg[0]) for c in gen(*coord)])]) for coord, v in I.items()])
    if iteration == 1:
        for i in range(-2, 102):
            for j in range(-2, 102):
                print("#" if I[(i, j)] else ".", end='')
            print()
        # print(min(I))
        print("sum after  2 iters", sum(I.values()))
        exit(0)
# print("sum after 50 iters", sum(I.values()))
