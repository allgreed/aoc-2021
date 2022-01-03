import sys
import functools
import itertools
import time
import re
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
            input_ranges.append(parse_line(l))

    REACTOR_SIZE = 10 ** 6
    reactor = [Range(-REACTOR_SIZE, REACTOR_SIZE, [Range(-REACTOR_SIZE, REACTOR_SIZE, [Range(-REACTOR_SIZE, REACTOR_SIZE, State.Off)])])]

    input_ranges = list(filter(bool, input_ranges))

    print("-------- BEGIN --------")
    # list(map(print, reactor[0].shallow_split(input_ranges[0])))
    new_reactor = deep_split(reactor, input_ranges[0])
    new_reactor = deep_split_l(new_reactor, input_ranges[0])
    print(reactor[0].complexity())
    print(sum(map(lambda r: r.complexity(), new_reactor)))
    print("done", time.time() - start_time)


def pprint(rl):
    list(map(print, rl))
    return 

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
        return other.end >= self.start or other.start <= self.end

    def shallow_split(self: 'Range', other: 'Range') -> List['Range']:
        # test
        if (self.start >= other.start and self.end <= other.end):
            return [self]

        l_split = other.start >= self.start
        r_split = other.end <= self.end
        both_split = r_split and l_split
              
        v = self.value
        if both_split:
            return [
                Range(other.start, other.end, v.copy()),
                Range(self.start, other.start - 1, v.copy()),
                Range(other.end + 1, self.end, v),
            ]
        elif r_split:
            assert self.start <= other.end <= self.end, f"{self.start} <= {other.end} <= {self.end}, {other.start}"
            return [
                Range(self.start, other.end, v.copy()),
                Range(other.end + 1, self.end, v),
            ]
        elif l_split:
            # TODO: ???
            # assert other.start <= self.end <= self.start
            return [
                Range(other.start, self.end, v),
                Range(self.start, other.start - 1, v.copy()),
            ]
        else:
            assert 0, "unreachable"

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


def deep_split_l(r: List['Range'], s: 'Range') -> List['Range']:
    print("deep", r)
    if isinstance(r, Range):
        return deep_split(r, s) 

    result = []

    # TODO: binsearch if I feel like it
    r_idx = 0
    while(not r[r_idx].overlap(s)):
        r_idx += 1

    # TODO: off by one?
    result += r[:r_idx]

    while(r[r_idx].overlap(s)):
        result += deep_split_l(r[r_idx], s)
        r_idx += 1

    # TODO: off by one?
    result += r[r_idx:]
    return result



def deep_split(r: List['Range'], s: 'Range') -> 'Range':
    if isinstance(r, list) and len(r) == 1:
        r = r[0]

    # if isinstance(r,list):
        # print(r)
    prod = r.shallow_split(s)
    
    # assert prod[0].start == s.start
    # assert prod[0].end == s.end
    chosen = prod[0]

    if isinstance(s.value, State):
        chosen.value = s.value
        # TODO: sort!!!!
        return sorted(prod)
    else:
        prod[0] = Range(prod[0].start, prod[0].end, deep_split(prod[0].value, s.value[0]))
        return sorted(prod)



def parse_line(line):
    _s, *_cords = DA_REGEXP.match(line).groups()
    s = State.On if _s == "on" else State.Off
    cords = list(_cords)

    if any(abs(int(c)) > 50 for c in cords):
        return

    x0, x1, y0, y1, z0, z1 = map(int, cords)

    z = Range(z0, z1, s)
    y = Range(y0, y1, [z])
    return Range(x0, x1, [y])


if __name__ == "__main__":
    main()
