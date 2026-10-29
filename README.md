# freshGram-nix

## Cache

https://freshgram-nix.cachix.org

```nix
nix.settings = {
  substituters = [ "https://freshgram-nix.cachix.org" ];
  trusted-public-keys = [ "freshgram-nix.cachix.org-1:ecq4K1oaPvsfhbdVsaU8lp6jpCzGID3obEWF2wpfqZE=" ];
};
```

## Usage

```bash
nix build github:ArisoN-ext/freshGram-nix
nix run github:ArisoN-ext/freshGram-nix
```

```nix
inputs.freshGram-nix.url = "github:ArisoN-ext/freshGram-nix";
```

## Develop shell

```
nix develop github:ArisoN-ext/freshGram-nix
```
