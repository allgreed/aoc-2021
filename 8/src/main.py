import sys
import string
from contextlib import suppress

def main():
    with open(sys.argv[1]) as f:
        lines = f.readlines()

    cumsum = 0
    for line in lines:
        _mapping, _display = line.split("|")
        mapping, display = _mapping.strip().split(" "), _display.strip().split(" ")

        non_trivial_mappings = []
        digimap = {}
        wiremap = {}
        LEN_TO_NUMBER = {2: 1, 4: 4, 3: 7, 7: 8}
        for code in mapping:
            if (len(code) in LEN_TO_NUMBER.keys()):
                digimap[LEN_TO_NUMBER[len(code)]] = code
            else:
                non_trivial_mappings.append(code)


        for c in (set(string.ascii_lowercase[:8]).difference(set(digimap[7]))):
            if len(non_trivial_mappings) - sum(1 if c in x else 0 for x in non_trivial_mappings) == 1:
                # character -> d
                wiremap["d"] = c

        map0 = set(filter(lambda m: wiremap["d"] not in m, non_trivial_mappings)).pop()
        non_trivial_mappings.remove(map0)
        digimap[0] = map0

        wiremap["a"] = set(digimap[7]).difference(set(digimap[1])).pop()
        
        wiremap["b"] = set(digimap[4]).difference(set(digimap[1])).difference({wiremap["d"]}).pop()

        from collections import Counter 
        chars = [c for c in sum(list(map(list, non_trivial_mappings)), []) if c not in wiremap.values()]
        c = Counter(chars)
        ble = {4: "f", 2: "e", 3: "c",5: "g"}
        for char, count in c.items():
            wiremap[ble[count]] = char

        r_wiremap = {v: k for k,v in wiremap.items()}

        for nt in non_trivial_mappings:
            decoded_nt = "".join(sorted(map(lambda c: r_wiremap[c], nt)))

            args = {
                "acdeg": 2,
                "acdfg": 3,
                "abdfg": 5,
                "abdefg": 6,
                "abcdfg": 9,
            }
            digimap[args[decoded_nt]] = nt

        rev_digimap = { "".join(sorted(v)): k for k, v in digimap.items()}

        x = int("".join(map(str, (rev_digimap["".join(sorted(d))] for d in display))))

        cumsum += x

    assert cumsum == 61229
    print(cumsum)


if __name__ == "__main__":
    main()
