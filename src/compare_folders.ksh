#!/bin/ksh
#
# AフォルダーとBフォルダーのファイルをタイムスタンプとサイズで再帰的に比較する
#
# 使用方法: ./compare_folders.ksh <Aフォルダ> <Bフォルダ> [出力ファイル]
#   例: ./compare_folders.ksh /data/A /data/B
#       ./compare_folders.ksh /data/A /data/B /tmp/report.txt
#

if [[ $# -lt 2 || $# -gt 3 ]]; then
    print "使用方法: $0 <Aフォルダ> <Bフォルダ> [出力ファイル]" >&2
    exit 1
fi

DIR_A="${1%/}"
DIR_B="${2%/}"
OUTPUT="${3:-diff_report_$(date +%Y%m%d_%H%M%S).txt}"

if [[ ! -d "$DIR_A" ]]; then
    print "エラー: Aフォルダーが存在しません: $DIR_A" >&2
    exit 1
fi

if [[ ! -d "$DIR_B" ]]; then
    print "エラー: Bフォルダーが存在しません: $DIR_B" >&2
    exit 1
fi

# stat コマンドの形式を判定（GNU stat / BSD stat）
if stat -c '%Y %s' "$DIR_A" >/dev/null 2>&1; then
    STAT_FMT=gnu
elif stat -f '%m %z' "$DIR_A" >/dev/null 2>&1; then
    STAT_FMT=bsd
else
    print "エラー: stat コマンドが使用できません" >&2
    exit 1
fi

# タイムスタンプ（Unix秒）とサイズを返す: "mtime size"
get_stat() {
    if [[ $STAT_FMT == gnu ]]; then
        stat -c '%Y %s' "$1" 2>/dev/null
    else
        stat -f '%m %z' "$1" 2>/dev/null
    fi
}

# Unix タイムスタンプを人が読める形式に変換
fmt_time() {
    if [[ $STAT_FMT == gnu ]]; then
        date -d "@$1" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || print "$1"
    else
        date -r "$1" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || print "$1"
    fi
}

# 出力バッファ用一時ファイル
TMP_A_ONLY=$(mktemp)
TMP_B_ONLY=$(mktemp)
TMP_DIFF=$(mktemp)

trap 'rm -f "$TMP_A_ONLY" "$TMP_B_ONLY" "$TMP_DIFF"' EXIT

cnt_a_only=0
cnt_b_only=0
cnt_diff=0

# --- Aフォルダーを起点に走査 ---
find "$DIR_A" -type f | sort | while read file_a; do
    rel="${file_a#${DIR_A}/}"
    file_b="$DIR_B/$rel"

    if [[ ! -f "$file_b" ]]; then
        print "  $rel" >> "$TMP_A_ONLY"
    else
        set -- $(get_stat "$file_a")
        mtime_a=$1; size_a=$2

        set -- $(get_stat "$file_b")
        mtime_b=$1; size_b=$2

        if [[ "$mtime_a" != "$mtime_b" || "$size_a" != "$size_b" ]]; then
            # 差異の種別を判定
            if [[ "$mtime_a" != "$mtime_b" && "$size_a" != "$size_b" ]]; then
                diff_kind="タイムスタンプ＋サイズ"
            elif [[ "$mtime_a" != "$mtime_b" ]]; then
                diff_kind="タイムスタンプ"
            else
                diff_kind="サイズ"
            fi

            time_a=$(fmt_time "$mtime_a")
            time_b=$(fmt_time "$mtime_b")

            {
                print "  [$diff_kind] $rel"
                print "    A: $time_a  ${size_a} bytes"
                print "    B: $time_b  ${size_b} bytes"
            } >> "$TMP_DIFF"
        fi
    fi
done

# カウント（サブシェル問題回避のため wc で集計）
cnt_a_only=$(wc -l < "$TMP_A_ONLY" | tr -d ' ')
cnt_diff_lines=$(grep -c '^\s*\[' "$TMP_DIFF" 2>/dev/null || print 0)
cnt_diff=$cnt_diff_lines

# --- Bのみ存在するファイルを走査 ---
find "$DIR_B" -type f | sort | while read file_b; do
    rel="${file_b#${DIR_B}/}"
    file_a="$DIR_A/$rel"
    if [[ ! -f "$file_a" ]]; then
        print "  $rel" >> "$TMP_B_ONLY"
    fi
done

cnt_b_only=$(wc -l < "$TMP_B_ONLY" | tr -d ' ')

# --- レポート生成 ---
{
    sep="=================================================="
    print "$sep"
    print "ファイル差分レポート"
    print "実行日時  : $(date '+%Y-%m-%d %H:%M:%S')"
    print "Aフォルダー: $DIR_A"
    print "Bフォルダー: $DIR_B"
    print "$sep"
    print ""

    print "[Aのみ存在: ${cnt_a_only}件]"
    if [[ $cnt_a_only -gt 0 ]]; then
        cat "$TMP_A_ONLY"
    else
        print "  (なし)"
    fi
    print ""

    print "[Bのみ存在: ${cnt_b_only}件]"
    if [[ $cnt_b_only -gt 0 ]]; then
        cat "$TMP_B_ONLY"
    else
        print "  (なし)"
    fi
    print ""

    print "[差異あり: ${cnt_diff}件]"
    if [[ $cnt_diff -gt 0 ]]; then
        cat "$TMP_DIFF"
    else
        print "  (なし)"
    fi
    print ""

    total=$((cnt_a_only + cnt_b_only + cnt_diff))
    print "$sep"
    print "集計: Aのみ ${cnt_a_only}件 / Bのみ ${cnt_b_only}件 / 差異あり ${cnt_diff}件 / 合計 ${total}件"
    print "$sep"
} > "$OUTPUT"

cat "$OUTPUT"
print ""
print "レポートを出力しました: $OUTPUT"
