from dataclasses import dataclass
from typing import Tuple
import itertools; from collections import Counter

@dataclass
class Player:
    pos: int
    score: int

@dataclass
class World:
    players: Tuple[Player, Player]

TARGET_SCORE = 7
STEPS = 3


def main():
    _d = list(range(1, 4))
    ble = list(map(sum, (itertools.product(_d, _d, _d))))
    daiz = list(itertools.product(*itertools.repeat(ble,STEPS)))

    p1, p2, inconclusive = 0,0,0
    for d in daiz:
        players = [Player(4, 0), Player(8, 0)]
        blorg = 0
        cpi = 1 
          
        while (players[cpi].score < TARGET_SCORE):
            cpi = not cpi
            cp = players[cpi]
            try:
                dice_rolls = d[blorg]
            except IndexError:
                inconclusive += 1
                break

            cp.pos = circular(cp.pos + dice_rolls)
            cp.score += cp.pos
            blorg += 1
        else:
            if cpi:
                p2 += 1
            else:
                p1 += 1

    print(sum([p1, p2, inconclusive]))
    print(p1, p2, inconclusive)


def circular(x, n=10):
    result = x % 10 if x > n else x
    if result == 0:
        return n
    else:
        return result

if __name__ == "__main__":
    main()
