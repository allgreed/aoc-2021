with open("input") as f:
    lines = f.readlines() 
    j = -1
    for i, line in enumerate(lines):
        if line.startswith("inp"):
            j += 1

            lines[i:i+18]
            with open(f"input_{j}", "w") as ff:
                ff.write("".join())
