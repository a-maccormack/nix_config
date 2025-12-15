# NixOS Multi Host Config

### Check Config

```bash
nix flake check --impure
```

VM:

```bash
sudo nixos-rebuild switch --flake .#vm
```
