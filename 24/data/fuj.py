with open("input") as f:
    lines = f.readlines() 
    j = -1
    for i, line in enumerate(lines):
        if line.startswith("inp"):
            j += 1

            da_lines = lines[i:i+18]
            a = da_lines[4].split()[2]
            b = da_lines[5].split()[2]
            c = da_lines[15].split()[2]
            print(a, b, c)

