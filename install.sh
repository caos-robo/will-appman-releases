#!/bin/sh
# will-appman を入れる・更新する (流し直すと最新の版になる)
#   curl -fsSL https://raw.githubusercontent.com/caos-robo/will-appman-releases/main/install.sh | sh
# 置き場: ~/.local/share/will-appman/versions/<版>/ に展開し、~/.local/bin/will-appman をその版へのリンクにする
# sudo は使わない。rc は書き換えない。要るのは curl と tar だけ
set -eu

repo_url="https://github.com/caos-robo/will-appman-releases"
# 確かめるときだけ替える: 取り先 (<取り先>/<版>/<tar.gz> を取る。file:// でもよい) と版
download="${WILL_APPMAN_DOWNLOAD:-$repo_url/releases/download}"
version="${WILL_APPMAN_VERSION:-}"

share="$HOME/.local/share/will-appman"
bindir="$HOME/.local/bin"
link="$bindir/will-appman"

die() {
    printf 'will-appman の install: %s\n' "$*" >&2
    exit 1
}

for cmd in curl tar; do
    command -v "$cmd" >/dev/null 2>&1 || die "$cmd がありません"
done

# 1. OS・CPU
os=$(uname -s)
machine=$(uname -m)
# 配っているのは x64 だけ。arm64 は、Apple Silicon の mac で e2e (just test-e2e) を回すために受け付ける
# (Releases に arm64 向けは無いので、arm64 の PC では取るところで止まる)
case "$os/$machine" in
    Linux/x86_64 | Linux/amd64) arch=x64 ;;
    Linux/aarch64 | Linux/arm64) arch=arm64 ;;
    *) die "未対応の OS・CPU です: $os $machine (Linux の x64 向けだけを配っています)" ;;
esac

# 最新の版は、Releases の latest の転送先 (…/releases/tag/<版>) の末尾から読む (GitHub の API も jq も使わない)
if [ -z "$version" ]; then
    latest=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "$repo_url/releases/latest") \
        || die "最新の版を調べられませんでした: $repo_url/releases/latest"
    version=${latest##*/}
fi
case "$version" in
    v[0-9]*) ;;
    *) die "版がわかりませんでした: $version (まだ Releases に版が無いかもしれません)" ;;
esac

# 付け替える前にリンクが指している版 (1 つ前の版として残す)
previous=""
if [ -L "$link" ]; then
    previous=$(basename "$(dirname "$(readlink "$link")")")
fi

mkdir -p "$share/versions"
dest="$share/versions/$version"
if [ -x "$dest/will-appman" ]; then
    printf '%s はもう入っています。リンクだけ合わせます\n' "$version"
else
    # 2〜4. 一時フォルダに取って展開し、展開しきってから版のフォルダへ動かす (途中で落ちても今の版はそのまま)
    tmp=$(mktemp -d "$share/.install.XXXXXX")
    trap 'rm -rf "$tmp"' EXIT
    name="will-appman-$version-linux-$arch.tar.gz"
    url="$download/$version/$name"
    printf '%s を取っています: %s\n' "$version" "$url"
    curl -fsSL -o "$tmp/$name" "$url" \
        || die "取れませんでした: $url (この OS・CPU 向けの版が無いかもしれません)"
    mkdir "$tmp/files"
    tar -xzf "$tmp/$name" -C "$tmp/files" || die "展開できませんでした: $name"
    [ -x "$tmp/files/will-appman" ] || die "tar.gz にランチャー will-appman がありません: $name"
    rm -rf "$dest"
    mv "$tmp/files" "$dest"
fi

# 5. リンクを付け替える (隣に作ってから名前を変えるので、付け替えの途中でリンクが消えない)
created_bindir=false
if [ ! -d "$bindir" ]; then
    mkdir -p "$bindir"
    created_bindir=true
fi
ln -sf "$dest/will-appman" "$bindir/.will-appman.new"
mv -f "$bindir/.will-appman.new" "$link"

# 6. 今の版と 1 つ前の版だけ残す
# 同じ版を流し直したときは、付け替える前も今の版を指しているので、1 つ前がわからない。消さずに残す
[ "$previous" = "$version" ] && previous_unknown=true || previous_unknown=false
for dir in "$share/versions"/*; do
    [ "$previous_unknown" = true ] && break
    [ -d "$dir" ] || continue
    v=$(basename "$dir")
    [ "$v" = "$version" ] && continue
    [ "$v" = "$previous" ] && continue
    rm -rf "$dir"
done

printf 'will-appman %s を入れました: %s\n' "$version" "$link"
# 7. ~/.local/bin を初めて作ったときは、ログインし直すまで PATH に入っていない (Ubuntu の ~/.profile が入れる)
if [ "$created_bindir" = true ]; then
    printf '%s を作りました。ログインし直すか、. ~/.profile を打つと will-appman が使えます\n' "$bindir"
fi
