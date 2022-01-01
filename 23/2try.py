import sys
import itertools
import functools
import copy
import math
from ptpython.repl import embed
from collections import deque

import matplotlib
import networkx as nx

HOW_MANY_ROOMS = 4

def main():
    fname = sys.argv[1]

    _g = nx.Graph()
    for i in range(11):
        _g.add_node(i, contents=None)
    for i in range(10):
        _g.add_edge(i, i + 1)

    for i in range(4):
        intersection = 2 * i + 2
        it = intersection
        for j in range(HOW_MANY_ROOMS):
            new = 11 * (i + 1) + j
            _g.add_edge(it, new)
            it = new

    with open(fname) as f:
        for i, l in enumerate(filter(lambda l: any(c in l for c in {"A","B", "C"}), f.readlines())):
            l = l.replace("#", "").strip()
            for j, c in enumerate(l):
                _g.nodes[11 * (j + 1) + i]["contents"] = c

    _g.graph["moves"] = []
    _g.graph["energy"] = 0
    _g.graph["placed"] = set()

    _graphs = deque([(_g, -1)])
    minng = _g
    minnv = math.inf
    # minnv = 45000

    cache = {}

    i = 0
    # while(_graphs):
    for ii in range(10):
        # for jj in range(100):
        for jj in range(1000):
            try:
                g, prev_gen = _graphs.pop()
            except IndexError:
                continue

            if(g.graph["energy"] >= minnv):
                continue

            g_dump = dump(g)
            if(g_dump in cache):
                if cache[g_dump] <= g.graph["energy"]:
                    continue
                else:
                    cache[g_dump] = g.graph["energy"]
            else:
                cache[g_dump] = g.graph["energy"]

            if(is_done(g)):
                minng = g
                minnv = g.graph["energy"]
                print("done!", g.graph["energy"])

            freenodes = list(filter(lambda n: g.nodes[n]["contents"] is not None, nx.nodes(g)))

            for n in list(filter(functools.partial(can_move, g=g), freenodes)):

                for p in possible_places(n, g):

                    new_g = copy.deepcopy(g)
                    d = distance(n, p, g.nodes[n]['contents'])
                    new_g.graph["energy"] += d
                    new_g.graph["moves"].append(f"{n} -> {p}: d{d} [{g.nodes[n]['contents']}]")
                    # if n in new_g.graph["placed"]:
                        # print(new_g.graph["moves"])
                        # print(dump(g)._d)
                        # raise
                    if p > 10:
                        new_g.graph["placed"].add(p)
                    # if f"{p} -> {n}: d{d} [{g.nodes[n]['contents']}]" in new_g.graph["moves"]:
                        # print(new_g.graph["moves"])
                        # print(dump(g)._d)
                        # raise
                    move(new_g, n, p)
                    _graphs.append((new_g, prev_gen + 1))
                
        i += 1
        print(i * 1000, len(_graphs), len([gen for _, gen in _graphs if gen < 1]))

    print()
    try:
        # g, _ = _graphs[-1]
        g = minng
    except IndexError:
        g = minng

    print(minnv)

    for m in g.graph["moves"]:
        print(m)

    print(dump(g)._d)
    # nx.draw(g, with_labels=True, labels = { n: ("" if g.nodes[n]["contents"] is None else str(g.nodes[n]["contents"]) + " - ") + str(n) for n in nx.nodes(g)})
    # matplotlib.pyplot.show()


def distance(n, p, c):
    a,b = sorted([n, p])
    d = 0

    if b > 10:
        i = b // 11 - 1
        intersection = 2 * i + 2
        d +=1 + b % 11
    else:
        raise

    if a > 10:
        i = a // 11 - 1
        d +=1 + a % 11
        a = 2 * i + 2

    d += abs(intersection - a)

    char_mod = ord(c) - ord("A")
    d *= 10 ** char_mod
    return d

assert(distance(33,0,"A") == 7)
assert(distance(11,44,"D") == 8000)
assert(distance(12,33,"C") == 700)

def move(g, n, p):
    c = g.nodes[n]["contents"]
    g.nodes[n]["contents"] = None
    assert g.nodes[p]["contents"] is None
    g.nodes[p]["contents"] = c

def possible_places(sn, g) -> list:
    visited = set()
    possible = set()
    q = [sn]
    c = g.nodes[sn]["contents"]

    while(q):
        cn = q.pop()
        for i in g[cn]:
            if i in visited:
                continue

            visited.add(i)
            if is_free(i, g):
                possible.add(i)
                q.append(i)

    r11set = set(range(11))
    no_hall_stall = possible.difference(set(range(2,9,2)))

    thats_my_spot = set()
    for pp in no_hall_stall:
        if pp not in r11set and not is_in_desired_spot(pp, g, c):
            thats_my_spot.add(pp)


    better = no_hall_stall.difference(thats_my_spot)

    no_hall_move = set()
    if sn in r11set:
        for pp in better:
            if pp in r11set: 
                no_hall_move.add(pp)

    betterer = better.difference(no_hall_move)

    desired_pos = ord(c) - ord("A")
    target_idx = 11 * (desired_pos + 1)


    offset = sn // 11

    # can only place item at bottom column
    for i in range(HOW_MANY_ROOMS - 1):
        if target_idx + i in betterer and target_idx + i + 1 in betterer:
            betterer.discard(target_idx + i)
            assert len(betterer) > 0


    # cannot place item in column if there is something to take out
    for i in range(HOW_MANY_ROOMS):
        if g.nodes[target_idx + i]["contents"] not in {c, None}:
            for i in range(HOW_MANY_ROOMS):
                betterer.discard(target_idx + i)

    # cmp_d = {0: None, 1: 'C', 2: None, 3: 'C', 4: None, 5: "B", 6: None, 7: 'C', 8: None, 9: 'A', 10: 'D', 11: 'B', 12: 'D', 13: 'D', 14: 'A', 22: None, 23: None, 24: 'B', 25: 'D', 33: None, 34: 'B', 35: 'A', 36: 'C', 44: None, 45: None, 46: None, 47: 'A'}
    # if sn == 5 and dump(g) == cmp_d:
        # embed(globals(), locals())
        # raise

    # cannot go from column to column
    if sn > 10:
        for i in range(HOW_MANY_ROOMS):
            betterer.discard(target_idx + i)


        # nx.draw(g, with_labels=True, labels = { n: ("" if g.nodes[n]["contents"] is None else str(g.nodes[n]["contents"]) + " - ") + str(n) for n in nx.nodes(g)})
        # matplotlib.pyplot.show()

        # embed(globals(), locals())
        # raise

    return list(betterer)

def is_done(g, ble=False):
    for i in range(4):
        for j in range(HOW_MANY_ROOMS):
            n = 11 * (i + 1) + j
            if (ble):
                print(n)
    
            if g.nodes[n]["contents"] is None or not is_in_desired_spot(n, g):
                return False

    return True


def can_move(n, g) -> bool:
    if(n > 10):
        offset = n // 11
        rel_idx = n % 11

        for i in range(1, rel_idx):
            assert i != 0
            real_idx = 11 * (offset) + i
            if not is_free(real_idx, g):
                return False

        for i in range(rel_idx, HOW_MANY_ROOMS):
            real_idx = 11 * (offset) + i
            if not is_in_desired_spot(real_idx, g):
                return True

        return False

    else: # 0..10
        c = g.nodes[n]["contents"]
        return any(map(functools.partial(is_in_desired_spot, g = g, c = c), possible_places(n, g)))

    assert 0 # unreachable


def is_free(n, g):
    c = g.nodes[n]["contents"]
    return c is None

def is_in_desired_spot(n, g, c = None):
    idx = n // 11 - 1
    c = c or g.nodes[n]["contents"]
    if c is None:
        return False
    desired_pos = ord(c) - ord("A")
    return idx == desired_pos


def dump(g) -> dict:
    return FrozenDict({n: g.nodes[n]["contents"] for n in g.nodes()})


# https://stackoverflow.com/a/2704866
import collections

class FrozenDict(collections.Mapping):
    """Don't forget the docstrings!!"""

    def __init__(self, *args, **kwargs):
        self._d = dict(*args, **kwargs)
        self._hash = None

    def __iter__(self):
        return iter(self._d)

    def __len__(self):
        return len(self._d)

    def __getitem__(self, key):
        return self._d[key]

    def __hash__(self):
        # It would have been simpler and maybe more obvious to 
        # use hash(tuple(sorted(self._d.iteritems()))) from this discussion
        # so far, but this solution is O(n). I don't know what kind of 
        # n we are going to run into, but sometimes it's hard to resist the 
        # urge to optimize when it will gain improved algorithmic performance.
        if self._hash is None:
            hash_ = 0
            for pair in self.items():
                hash_ ^= hash(pair)
            self._hash = hash_
        return self._hash

if __name__ == "__main__":
    main()
