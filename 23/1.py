import sys
import itertools
import functools
import copy
import math
from collections import deque

import matplotlib
import networkx as nx


def main():
    fname = sys.argv[1]

    _g = nx.Graph()
    for i in range(11):
        _g.add_node(i, contents=None)
    for i in range(10):
        _g.add_edge(i, i + 1)

    for i in range(4):
        intersection = 2 * i + 2
        new = 11 * (i + 1)
        new_next = new + 1

        _g.add_edge(intersection, new)
        _g.add_edge(new,new_next)

    with open(fname) as f:
        for i, l in enumerate(filter(lambda l: any(c in l for c in {"A","B", "C"}), f.readlines())):
            l = l.replace("#", "").strip()
            for j, c in enumerate(l):
                _g.nodes[11 * (j + 1) + i]["contents"] = c

    _g.graph["moves"] = []
    _g.graph["energy"] = 0

    # _graphs = [(_g, -1)]
    _graphs = deque([(_g, -1)])
    minng = _g
    minnv = math.inf
    # minnv = 12522

    cache = {}

    g1 = copy.deepcopy(_g)
    g2 = copy.deepcopy(_g)
    move(g1, 22, 3)
    move(g2, 22, 3)

    # cache[dump(g1)] = 5
    # print(cache[dump(g2)])

    i = 0
    while(_graphs):
    # for ii in range(10):
        # for jj in range(100):
        for jj in range(1000):
            try:
                g, prev_gen = _graphs.pop()
            except IndexError:
                continue
            # g, prev_gen = _graphs.popleft()

            if(g.graph["energy"] >= minnv):
                continue

            g_dump = dump(g)
            if(g_dump in cache):
                if cache[g_dump] <= g.graph["energy"]:
                    continue
                else:
                    cache[g_dump] = g.graph["energy"]
            else:
                # print(dump(g)._d)
                cache[g_dump] = g.graph["energy"]

            if(is_done(g)):
                minng = g
                minnv = g.graph["energy"]
                print("done!", g.graph["energy"])

            freenodes = list(filter(lambda n: g.nodes[n]["contents"] is not None, nx.nodes(g)))
            # print(list((f, g.nodes[f]["contents"]) for f in freenodes))

            for n in list(filter(functools.partial(can_move, g=g), freenodes)):

                for p in possible_places(n, g):

                    new_g = copy.deepcopy(g)
                    d = distance(n, p, g.nodes[n]['contents'])
                    new_g.graph["energy"] += d
                    new_g.graph["moves"].append(f"{n} -> {p}: d{d} [{g.nodes[n]['contents']}]")

                    if len(new_g.graph["moves"]) > 3 and new_g.graph["moves"][-1] == new_g.graph["moves"][-3]:
                        for m in new_g.graph["moves"]:
                            print(m)

                        nx.draw(g, with_labels=True, labels = { n: ("" if g.nodes[n]["contents"] is None else str(g.nodes[n]["contents"]) + " - ") + str(n) for n in nx.nodes(g)})
                        matplotlib.pyplot.show()
                        
                        raise 

                    move(new_g, n, p)
                    _graphs.append((new_g, prev_gen + 1))
                
        i += 1
        print(i * 1000, len(_graphs), len([gen for _, gen in _graphs if gen < 1]))

    print()
    g = minng
    print(minnv)
    for m in g.graph["moves"]:
        print(m)
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
        for n in g[cn]:
            if n in visited:
                continue

            visited.add(n)

            if is_free(n, g):
                possible.add(n)
                q.append(n)

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

    if target_idx in betterer and target_idx + 1 in betterer:
        betterer.remove(target_idx)

    if target_idx in betterer and g.nodes[target_idx + 1]["contents"] != c:
        betterer.remove(target_idx)

    return list(betterer)

def is_done(g, ble=False):
    for i in range(4):
        for j in range(2):
            n = 11 * (i + 1) + j
            if (ble):
                print(n)
    
            if g.nodes[n]["contents"] is None or not is_in_desired_spot(n, g):
                return False

    return True


def can_move(n, g) -> bool:
    if (n % 11 == 0) and (n > 10):
        return not (is_in_desired_spot(n, g) and is_in_desired_spot(n + 1, g))

    elif (n % 11 == 1) and (n > 10):
        return (not is_in_desired_spot(n, g)) and is_free(n - 1, g)

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
