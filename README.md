# will-appman

will の機器で、アプリを入れ・切り替え・管理する道具です。作業 PC (Linux の x64。Ubuntu・WSL2) で使います。

## 入れ方・更新の仕方

```sh
curl -fsSL https://raw.githubusercontent.com/caos-robo/will-appman-releases/main/install.sh | sh
```

同じコマンドを流し直すと、最新の版に更新されます。sudo は要りません。

- `~/.local/share/will-appman/versions/<版>/` に入り、`~/.local/bin/will-appman` がその版を指します
- 今の版と 1 つ前の版だけを残します。前の版に戻すときは、`~/.local/bin/will-appman` のリンクをその版に張り直します
- `~/.local/bin` を初めて作ったときは、ログインし直すか `. ~/.profile` を打つと使えるようになります

## 使い方

```sh
will-appman --help
will-appman --version
```
