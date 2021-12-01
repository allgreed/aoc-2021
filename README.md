# AoC 2021
Solutions to [Advent of Code 2021](https://adventofcode.com/2021/) in [zig](https://ziglang.org/)

## Usage
For now go for [dev](#dev)

## Dev

### Prerequisites
- [nix](https://nixos.org/nix/manual/#chap-installation)
- `direnv` (`nix-env -iA nixpkgs.direnv`)
- [configured direnv shell hook ](https://direnv.net/docs/hook.html)
- some form of `make` (`nix-env -iA nixpkgs.gnumake`)

Hint: if something doesn't work because of missing package please add the package to `default.nix` instead of installing it on your computer. Why solve the problem for one if you can solve the problem for all? ;)

Also: if the direnv doesn't is work properly *and* it is installed via nix-env -> make sure your profile is sourced in your shellrc (`source ~/.nix-profile/etc/profile.d/nix.sh`).

### One-time setup
```
make init
```

### Everything
```
make help
```
