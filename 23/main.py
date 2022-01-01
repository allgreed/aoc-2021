import sys
import functools
import itertools
import heapq
import time
from collections import defaultdict

import matplotlib
import networkx as nx

ROOMS = 4
def mk_structure_graph():
    _g = nx.Graph()
    for i in range(11):
        _g.add_node(i, contents=None)
    for i in range(10):
        _g.add_edge(i, i + 1)

    for i in range(4):
        intersection = 2 * i + 2
        it = intersection
        for j in range(ROOMS):
            new = 11 * (i + 1) + j
            _g.add_edge(it, new)
            it = new

    return _g
G = mk_structure_graph()

SOL = [
# ".......BDDACCBDBBACDACA",
"......DBDDACCBDBBAC.ACA",
"A.....DBDDACCBDBBAC..CA",
"A....BDBDDACCBD.BAC..CA",
"A...BBDBDDACCBD..AC..CA",
"AA..BBDBDDACCBD...C..CA",
"AA..BBDBDDA.CBD..CC..CA",
"AA..BBDBDDA..BD.CCC..CA",
"AA.BBBDBDDA...D.CCC..CA",
"AADBBBDBDDA.....CCC..CA",
"AAD.BBDBDDA...B.CCC..CA",
"AAD..BDBDDA..BB.CCC..CA",
"AAD...DBDDA.BBB.CCC..CA",
"AAD...DBDDA.BBBCCCC...A",
"AAD..ADBDDA.BBBCCCC....",
"AA...ADBDDA.BBBCCCC...D",
"AA...AD.DDABBBBCCCC...D",
"AA...AD..DABBBBCCCC..DD",
"AAD..AD...ABBBBCCCC..DD",
"A.D..AD..AABBBBCCCC..DD",
"..D..AD.AAABBBBCCCC..DD",
".....AD.AAABBBBCCCC.DDD",
"......DAAAABBBBCCCC.DDD",
]

def main():
    start_time = time.time()
    fname = sys.argv[1]
    with open(fname) as f:
        initial_state = { n: None for n in range(11) if n not in {2,4,6,8}}
        for i, l in enumerate(filter(lambda l: any(c in l for c in {"A","B", "C"}), f.readlines())):
            l = l.replace("#", "").strip()
            for j, c in enumerate(l):
                initial_state[11 * (j + 1) + i] = c

    inistail_h = hscore(initial_state)
    heap = []
    heapq.heappush(heap, (inistail_h, inistail_h, 0, 0, initial_state, []))
    cache = {}
    cache_hits = 0
    
    last = None
    for _ in range(400000):
        try:
            elem = heapq.heappop(heap)
            last = elem
        except IndexError:
            pass

        f, h, g, _, state, moves = elem

        if h == 0:
            print("A!", new_f, new_state)
            print(moves)
            exit(0)

        state_repr = hash_dict(state)
        if state_repr in cache and cache[state_repr] <= f:
            cache_hits += 1
            continue
        cache[state_repr] = f

        am = available_moves(state)

        if state_repr in SOL:
            idx = SOL.index(state_repr)
            print("found sol", idx, f)

        for m in am:
            new_state = state.copy()
            mv = move(new_state, *m)

            new_h = hscore(new_state)
            new_g = mv + g
            new_f = new_h + new_g

            state_repr = hash_dict(new_state)
            if state_repr in cache and cache[state_repr] <= new_f:
                cache_hits += 1
                continue

            heapq.heappush(heap, (new_f, new_h, new_g, Choicer(), new_state, moves.copy() + [m]))

    print(len(heap))
    print(len(cache))
    print(cache_hits)
    elem = last
    print(elem)

    print("done", time.time() - start_time)
    plot(elem[4])


@functools.total_ordering
class Choicer:
    def __eq__(self, other):
        return False
    def __lt__(self, other):
        return False


def hash_dict(d):
    # return tuple(sorted(d.items()))
    return "".join(map(lambda x: "." if x[1] is None else x[1], tuple(sorted(d.items()))))


def is_done(state):
    # TODO: do
    return False


def hscore(state, debug=False):
    isk = list(state.keys())
    stack_positions = isk[7:]

    hscore = 0
    for n in state.keys():
        if is_free(state,n):
            continue

        dsi = desired_stack_idx(state, n)
        if n < 11 or desired_stack_idx(state, n) != stack_idx(n):
            despos = dsi * 11 + 3
            d = distance(n, despos)
            d *= valuate(state[n])
            hscore += d

    if hscore > 0:
        hscore += 10000
    
    return hscore

def available_moves(state):
    isk = list(state.keys())
    hall_postions = isk[:7]
    stack_positions = isk[7:]
    is_movable_f = functools.partial(movable, state)

    # heuristic: if I can put something in the stack I do that
    for n, moves in zip(hall_postions, map(is_movable_f, hall_postions)):
        if moves:
            assert len(moves) == 1
            return [(n, next(iter(moves)))]

    move_templates = filter(lambda x: x[1], zip(stack_positions, map(is_movable_f, stack_positions)))
    return sum(map(lambda mt: list(itertools.product([mt[0]], mt[1])), move_templates), [])


def movable(state, n):
    if state[n] is None:
        return []

    dsi = desired_stack_idx(state, n)
    reachable_positions = reachable(state, n)
    if n < 11: # hall logic
        if (is_well_formed(state, dsi)):
            is_top_f = functools.partial(is_stack_top, state)
            is_free_f = functools.partial(is_free, state)
            try:
                top = next(filter(is_top_f, stack_coords(dsi)))
                result = next(filter(is_free_f, get_neighbours(top)))
            except StopIteration:
                result = max(stack_coords(dsi))
            assert result > 10, "the stack cannot be full if there is a desired element in the hall"
            return {result}.intersection(reachable_positions)
        else:
            return [] 
    else: # stack logic
        si = stack_idx(n)
        if is_stack_top(state, n) and (dsi == si or not is_well_formed(state, si)):
            return list({0,1,3,5,7,9,10}.intersection(reachable_positions))
        else:
            return []


def reachable(state, a):
    visited = set()
    avaiable = set()
    stack = [a]
    while stack:
        v = stack.pop()
        for n in get_neighbours(v):
            if n not in visited:
                visited.add(n)
                if is_free(state,n):
                    stack.append(n)
                    avaiable.add(n)

    return avaiable


def desired_stack_idx(state, n):
    assert state[n] is not None, f"{n}"
    return ord(state[n]) - ord("A") + 1


def stack_coords(stack_idx):
    return (11 * stack_idx + i for i in range(4))


def is_well_formed(state, stack_idx):
    dsi = functools.partial(desired_stack_idx, state)
    free = functools.partial(is_free, state)
    dsi_or_empty = lambda n: free(n) or dsi(n) == stack_idx

    return all(map(dsi_or_empty, stack_coords(stack_idx)))


def stack_idx(n):
    assert n > 10
    return n // 11

def is_stack_top(state, n):
    if n < 11:
        return False
    if state[n] is None:
        return False

    stack_cords = [11 * stack_idx(n) + i for i in range(4)]

    for c in stack_cords:
        if c == n:
            break
        if state[c] is not None:
            return False

    return True


def move(state, n, new_n):
    assert is_free(state, new_n)
    state[n], state[new_n] =  state[new_n], state[n]

    d = distance(n, new_n)
    d *= valuate(state[new_n])

    return d

def valuate(c):
    return 10 ** (ord(c) - ord("A"))


@functools.lru_cache(maxsize=None)
def distance(a, b):
    visited = {a}
    stack = [(a, 0)]
    while stack:
        v, dist = stack.pop()
        if v == b:
            return dist

        for n in get_neighbours(v):
            if n not in visited:
                visited.add(n)
                stack.append((n, dist +1))

    assert 0, "unreachable"


def get_neighbours(n):
    return G[n].keys()


def plot(state):
    color_map = []
    for n in G:
        try:
            if state[n] is None:
                color_map.append("white")
            elif state[n] == "A":
                color_map.append("yellow")
            elif state[n] == "B":
                color_map.append("brown")
            elif state[n] == "C":
                color_map.append("orange")
            elif state[n] == "D":
                color_map.append("purple")
            else:
                assert 0, f"unreachable {state[n]}"
        except KeyError:
            color_map.append("white")

    labels = { n: str(n) + ("[T]" if is_stack_top(state,n) else "") for n in nx.nodes(G)}
    nx.draw_kamada_kawai(G, with_labels=True, labels=labels, node_color=color_map)
    matplotlib.pyplot.show()


def is_free(state, x):
    try:
        return state[x] is None
    except KeyError:
        return True

if __name__ == "__main__":
    main()
