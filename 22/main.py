import sys
import re
import operator
from typing import Tuple, Self, Sequence, Set
from dataclasses import dataclass
from pprint import pprint
from functools import reduce

import pytest
from pydantic import BaseModel


def main():
    fname = sys.argv[1]

    with open(fname) as f:
        steps = filter(bool, map(parse_step, f.readlines()))

    cube_pool = []
    for i, step in enumerate(steps):
        print(i, step)
        s, c = step
        intersects = False
        for oc in cube_pool: 
            intersection = c.intersection(oc)
            if intersection.volume > 0:
                print("+", intersection)
                intersects = True
                print(c.distinc_sum(oc))
                raise NotImplementedError("code me!")
            else:
                pass

        if not intersects:
            if s is True:
                cube_pool.append(c)
            else:
                # noop efectively
                pass

    pprint(cube_pool)


# TODO: rather redundant, is it? ;)
class Point3(BaseModel):
    x: int
    y: int
    z: int


@dataclass(eq=True, frozen=True)
class LinearDistance:
    start: int
    end: int

    def overlap(self, other: Self) -> "LinearDistance":
        if self.start > other.end or self.end < other.start:
            return NullDistance()

        return LinearDistance(max(self.start, other.start),
               min(self.end, other.end))

    def distinc_sum(self, other: Self) -> Set["LinearDistance"]:
        """Sum expressed as up to 3 non-overlapping LinearDistances"""
        overlap = self.overlap(other)
        # TODO: does this matter?
        # actually, for non-overlapping distances this is just `{self, other}`
        assert overlap

        retval = {overlap}

        lhs = min(self.start, other.start)
        rhs = max(self.end, other.end)
        if lhs < overlap.start:
            retval.add(LinearDistance(lhs, overlap.start - 1))
        if rhs > overlap.end:
           retval.add(LinearDistance(overlap.end + 1, rhs))

        assert 2 <= len(retval) <= 3, len(retval)
        # TODO: assert retval don't overlap pairwise
        return retval

    def __len__(self):
        if self.end < self.start:
            return 0

        return(abs(self.start - self.end) + 1)

    def __bool__(self):
        return bool(len(self))

D = LinearDistance
@pytest.mark.parametrize("shuffle", [0, 1])
@pytest.mark.parametrize("a,b,result", [
    (D(1,2), D(1,3), {D(1,2), D(3,3)}),
    (D(2,2), D(1,3), {D(1,1), D(2,2), D(3,3)}),
    (D(2,3), D(1,3), {D(1,1), D(2,3)}),
])
def test_distinct_linar_sum(a, b, result, shuffle):
    if shuffle:
        a, b = b, a
    assert a.distinc_sum(b) == result


@dataclass(eq=True, frozen=True)
class Cuboid:
    xd: LinearDistance
    yd: LinearDistance
    zd: LinearDistance

    @classmethod
    def from_Point3s(cls, start, end):
        return cls(
        LinearDistance(start.x, end.x),
        LinearDistance(start.y, end.y),
        LinearDistance(start.z, end.z),
        )

    @property
    def volume(self):
        return reduce(operator.mul, map(len, [self.xd, self.yd, self.zd]), 1)

    def intersection(self, other: Self) -> "Cuboid":
        return Cuboid(
            self.xd.overlap(other.xd),
            self.yd.overlap(other.yd),
            self.zd.overlap(other.zd),
        )

    # TODO: is there a name for this?
    def distinc_sum(self, other: Self) -> Sequence["Cuboid"]:
        """Sum expressed as up to 7 non-overlapping Cuboids"""
        # TODO: contruct cuboids from combination of distinc_sums of component distances - figure out how!
        retval = []

        assert 2 < len(retval) <= 7
        return retval


def test_volume():
    _, c = parse_step("on x=10..12,y=10..12,z=10..12")
    assert c.volume == 27

@pytest.mark.parametrize("steps, volume", [
    (["on x=1..1,y=1..1,z=1..1", "on x=2..2,y=2..2,z=2..2"], 0),
    (["on x=10..12,y=10..12,z=10..12", "on x=11..13,y=11..13,z=11..13"], 27 - 19),
])
def test_intersection(steps, volume):
    assert len(steps) == 2
    _, c1 = parse_step(steps[0])
    _, c2 = parse_step(steps[1])

    assert c1.intersection(c2).volume == volume


DA_REGEXP = re.compile(r"(on|off) x=(-?\d+)..(-?\d+),y=(-?\d+)..(-?\d+),z=(-?\d+)..(-?\d+)")

# it's actually Optional[...], however linter won't shut up about it above
# where I need to focus
def parse_step(line: str) -> Tuple[bool, Cuboid]:
    # custom: for ease of testing
    if line.startswith("#"):
        return None

    state_string, *string_cords = DA_REGEXP.match(line).groups()

    x0, x1, y0, y1, z0, z1 = map(int, string_cords)
    state = True if state_string == "on" else False

    start = Point3(x=x0, y=y0, z=z0)
    end = Point3(x=x1, y=y1, z=z1)
    c = Cuboid.from_Point3s(start=start, end=end)
    return (state, c)


class NullDistance(LinearDistance):
    def __init__(self):
        pass

    def __len__(self):
        return 0


if __name__ == "__main__":
    main()
