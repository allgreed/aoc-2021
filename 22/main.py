import sys
import functools
import itertools
import time
import re
import copy
from enum import Enum
from typing import Union, List
from dataclasses import dataclass

DA_REGEXP = re.compile(r"(on|off) x=(-?\d+)..(-?\d+),y=(-?\d+)..(-?\d+),z=(-?\d+)..(-?\d+)")


def main():
    start_time = time.time()
    fname = sys.argv[1]

    input_ranges = []
    with open(fname) as f:
        lines = f.readlines()
        for l in lines:
            if l.startswith("#"):
                continue
            input_ranges.append(parse_line(l))

    REACTOR_SIZE = 10 ** 6
    reactor = [Range(-REACTOR_SIZE, REACTOR_SIZE, [Range(-REACTOR_SIZE, REACTOR_SIZE, [Range(-REACTOR_SIZE, REACTOR_SIZE, State.Off)])])]

    input_ranges = list(filter(bool, input_ranges))

    print("-------- BEGIN --------")
    new_reactor = reactor
    for input_r in input_ranges[:-1]:
        new_reactor = deep_split_l(new_reactor, input_r)
        # print(sum(map(lambda r: r.complexity(), new_reactor)), input_r.value[0].value[0].value)

    # pprint(new_reactor)
    print("-------- BLORG --------")
    # print(input_ranges[-1])
    new_reactor = deep_split_l(new_reactor, input_ranges[-1], debug=False)
    pprint(new_reactor)
    cumsum = sum(map(count_on, new_reactor))
    print("cumsum", cumsum)
    print("done", time.time() - start_time)

    model = [0] * 101
    for _i in range(-50, 51):
        i = _i
        model[i] = [0] * 101
        for _j in range(-50, 51):
            j = _j
            model[i][j] = [State.Off] * 101

    for input_r in input_ranges:
        r = input_r
        for i in range(r.start, r.end + 1):
            r = input_r.value[0]
            for j in range(r.start, r.end + 1):
                r = input_r.value[0].value[0]
                for k in range(r.start, r.end + 1):
                    model[i][j][k] = r.value

    blorg = 0
    for _i in range(-50, 51):
        for _j in range(-50, 51):
            for _k in range(-50, 51):
                i,j,k = _i, _j, _k
                if model[i][j][k] == State.On:
                    blorg += 1
                if model[i][j][k] != probe(_i,_j,_k, new_reactor):
                    print(_i, _j, _k, "AAAAA")
    print(blorg, blorg == cumsum)




class State(Enum):
    On = 1
    Off = 0

    def copy(self):
        return self


@functools.total_ordering
@dataclass
class Range:
    start: int
    end: int
    value: Union[List['Range'], State]

    def __lt__(self, other):
        if not isinstance(other, Range):
            return NotImplemented

        return self.start < other.start

    def overlap(self: 'Range', other: 'Range') -> bool:
        return other.end >= self.start and other.start <= self.end

    def shallow_split(self: 'Range', other: 'Range') -> List['Range']:
        v = self.value

        if (not self.overlap(other)):
            return []

        if (self.start >= other.start and self.end <= other.end):
            return [Range(self.start, self.end, copy.deepcopy(v))]

        l_split = other.start >= self.start
        r_split = other.end <= self.end
        both_split = r_split and l_split
              
        if both_split:
            return [
                Range(other.start, other.end, copy.deepcopy(v)),
                Range(self.start, other.start - 1, copy.deepcopy(v)),
                Range(other.end + 1, self.end, copy.deepcopy(v)),
            ]
        elif r_split:
            assert self.start <= other.end <= self.end, f"{self.start} <= {other.end} <= {self.end}, {other.start}"
            return [
                Range(self.start, other.end, copy.deepcopy(v)),
                Range(other.end + 1, self.end, copy.deepcopy(v)),
            ]
        elif l_split:
            # TODO: ???
            assert self.start <= other.start <= self.end
            return [
                Range(other.start, self.end, copy.deepcopy(v)),
                Range(self.start, other.start - 1, copy.deepcopy(v)),
            ]
        else:
            assert 0, "unreachable"

    def span(self):
        return abs(self.start - self.end) + 1

    def __str__(self):
        return self._str()

    def _str(self, idx=0):
        tab = "\t" * idx
        if isinstance(self.value, State):
            sub = tab + "\t" + str(self.value)
        else:
            sub = "\n".join(s._str(idx+1) for s in self.value)
        result = f"""{tab}start= {self.start}
{tab}end= {self.end}
{sub}"""

        return result

    def complexity(self):
        if isinstance(self.value, State):
            return 1
        else:
            return 1 + sum(r.complexity() for r in self.value)

def probe(x, y, z, r):
    rx = 0
    while(r[rx].end < x):
        rx += 1

    r = r[rx].value
    ry = 0
    while(r[ry].end < y):
        ry += 1

    r = r[ry].value

    rz = 0
    while(r[rz].end < z):
        rz += 1

    r = r[rz]

    return r.value


def count_on(r):
    cur = r.span()

    if isinstance(r.value, State):
        if r.value == State.Off:
            return 0
        else:
            return cur

    times_cur = lambda x: x * cur
    count_on_times_cur = lambda r: times_cur(count_on(r))

    return sum(map(count_on_times_cur, r.value))

def deep_split_l(r: List['Range'], s: 'Range', debug=False) -> List['Range']:
    result = []

    # TODO: binsearch if I feel like it
    r_idx = 0
    while(not r[r_idx].overlap(s)):
        r_idx += 1

    result += r[:r_idx]

    while(r[r_idx].overlap(s)):
        result += deep_split(r[r_idx], s, debug)

        r_idx += 1
        if r_idx == len(r):
            break

    result += r[r_idx:]
    return result



def deep_split(r: List['Range'], s: 'Range', debug=False) -> List['Range']:
    if isinstance(r, list) and len(r) == 1:
        r = r[0]
    if isinstance(r, list):
        return deep_split_l(r, s, debug)

    prod = r.shallow_split(s)
    chosen = prod[0]

    if isinstance(s.value, State):
        if debug:
            print(prod, prod.index(chosen))
        chosen.value = s.value
        return sorted(prod)
    else:
        prod[0] = Range(prod[0].start, prod[0].end, deep_split(prod[0].value, s.value[0], debug))
        return sorted(prod)



def parse_line(line):
    _s, *_cords = DA_REGEXP.match(line).groups()
    s = State.On if _s == "on" else State.Off
    cords = list(_cords)

    # TODO: without this
    if any(abs(int(c)) > 50 for c in cords):
        return

    x0, x1, y0, y1, z0, z1 = map(int, cords)

    z = Range(z0, z1, s)
    y = Range(y0, y1, [z])
    return Range(x0, x1, [y])


def pprint(rl):
    if not isinstance(rl, list):
        rl = [rl]
    list(map(print, rl))
    return 


if __name__ == "__main__":
    main()
