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

    S = [("start", set(), "", ["start"])]
    while S:
        p, visited, c, path = S.pop()

        for v in ble[p]:
            fuj = [c]
            if v == "end":
                cumsum += 1
                path.append("end")
                # print(",".join(path))
                continue
            if v == "start":
                continue

            if v in visited:
                if fuj[0] == "":
                    fuj[0] = v
                else:
                    continue

            if v.islower():
                S.append((v, set_append(visited, v), fuj[0], path + [v]))
            else:
                S.append((v, visited, fuj[0], path + [v]))

    print(cumsum)


def set_append(s, i):
    sx = s.copy()
    sx.add(i)
    return sx


if __name__ == "__main__":
    main()
