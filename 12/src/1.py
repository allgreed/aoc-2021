import sys
from collections import defaultdict


def main():
    with open(sys.argv[1]) as f:
        lines = f.readlines()

    ble = defaultdict(list)

    for line in lines:
        line = line.rstrip()
        fr, to = line.split("-")
        ble[fr].append(to)
        ble[to].append(fr)

    cumsum = 0

    S = [("start", set())]
    while S:
        # print(S, cumsum)
        p, visited = S.pop()
        for v in ble[p]:
            if v == "end":
                cumsum += 1
                continue
            if v == "start":
                continue

            if v in visited:
                continue

            if v.islower():
                S.append((v, set_append(visited, v)))
            else:
                S.append((v, visited))

    print(cumsum)


def set_append(s, i):
    sx = s.copy()
    sx.add(i)
    return sx


if __name__ == "__main__":
    main()
