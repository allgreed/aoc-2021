with open("inputs/sol_test.txt") as f:
    print("---------------")
    hall = True
    acc = ""
    cols = []
    for l in f.readlines():
        l = l.rstrip()

        if l == "":
            for i in range(4):
                for j in range(4):
                    acc += cols[j][i]

            print(acc)
            acc = ""
            cols = []
            hall = True
        else:
            if l[3] == "#":
                pass
            elif hall:
                # print(list(enumerate(l)))
                for i,c in enumerate(l):
                    if i in set(range(3,10,2)) or c in {"#", " "}:
                        pass
                    else:
                        acc += c
                hall = False
            else:
                col = []
                for c in l:
                    if c in {"#", " "}:
                        pass
                    else:
                        col.append(c)
                cols.append(col)
