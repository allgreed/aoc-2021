from collections import defaultdict

# 400 is too low
# 556 is too high

def main():
    # with open("test.txt") as f:
    with open("real.txt") as f:
        data = f.readlines()

    scanners_points = []
    idx = -1
    for l in data:
        if l[0] == "\n":
            continue
        elif l.startswith("---"):
            idx += 1
            scanners_points.append([]);
        else:
            scanners_points[idx].append(eval("(" + l.rstrip() + ")"))
            

    distances = list(map(compute_distances, scanners_points))

    zorg = lambda: defaultdict(set)
    overlapping = defaultdict(zorg)
    cumsum = 0

    print("---")
    for i, psl in enumerate(distances):
        for j, psr in enumerate(distances[i + 1:]):
            j += i + 1
            if psl == psr:
                continue

            acc = 0
            for k, ble in enumerate(psl):
                for l, fuj in enumerate(psr):
                    overlapping_d = sum([d in ble for d in fuj])
                    if overlapping_d > 10:
                        acc += 1
                        key,value = (((i, k),(j,l)))
                        scanner, point = key
                        overlapping[scanner][point].add(value)

            cumsum += acc
            if (acc > 0):
                print(f"becon {i} overlaps with becon {j} - {acc} points")

    print(cumsum)
    print(overlapping[2])
    print(sum(sum(map(len, o.values())) for o in overlapping.values()))
    print(list(map(len, overlapping.values())))

    print(sum(map(len, scanners_points)) - cumsum)

    

def compute_distances(ps):
    lv = []
    for lp in ps:
        lvp = set()
        for rp in ps:
            if lp == rp:
                continue

            x1,y1,z1 = lp
            x2,y2,z2 = rp

            d = (x1 - x2) ** 2 + (y1 - y2) ** 2 + (z1 - z2) ** 2
            lvp.add(d)  
        lv.append(lvp) 
    return lv


if __name__ == "__main__":
    main()
