#!/bin/ksh
#
# AフォルダーとBフォルダーのファイル内容を再帰的に比較する
# タイムスタンプ・パーミッションは無視し、バイト列のみで比較する
#
# 使用方法: ./compare_folders_content.ksh <Aフォルダ> <Bフォルダ> [出力ファイル]
#   例: ./compare_folders_content.ksh /data/A /data/B
#       ./compare_folders_content.ksh /data/A /data/B /tmp/report.txt
#

if [[ $# -lt 2 || $# -gt 3 ]]; then
    print "使用方法: $0 <Aフォルダ> <Bフォルダ> [出力ファイル]" >&2
    exit 1
fi

DIR_A="${1%/}"
DIR_B="${2%/}"
OUTPUT="${3:-content_diff_report_$(date +%Y%m%d_%H%M%S).txt}"

if [[ ! -d "$DIR_A" ]]; then
    print "エラー: Aフォルダーが存在しません: $DIR_A" >&2
    exit 1
fi

if [[ ! -d "$DIR_B" ]]; then
    print "エラー: Bフォルダーが存在しません: $DIR_B" >&2
    exit 1
fi

# cmp コマンドの確認
if ! command -v cmp >/dev/null 2>&1; then
    print "エラー: cmp コマンドが見つかりません" >&2
    exit 1
fi

# 出力バッファ用一時ファイル
TMP_A_ONLY=$(mktemp)
TMP_B_ONLY=$(mktemp)
TMP_DIFF=$(mktemp)

trap 'rm -f "$TMP_A_ONLY" "$TMP_B_ONLY" "$TMP_DIFF"' EXIT

# --- Aフォルダーを起点に走査 ---
find "$DIR_A" -type f | sort | while read file_a; do
    rel="${file_a#${DIR_A}/}"
    file_b="$DIR_B/$rel"

    if [[ ! -f "$file_b" ]]; then
        print "  $rel" >> "$TMP_A_ONLY"
    else
        # cmp -s: 内容が同一なら終了コード0、異なれば1
        if ! cmp -s "$file_a" "$file_b"; then
            print "  $rel" >> "$TMP_DIFF"
        fi
    fi
done

# --- Bのみ存在するファイルを走査 ---
find "$DIR_B" -type f | sort | while read file_b; do
    rel="${file_b#${DIR_B}/}"
    if [[ ! -f "$DIR_A/$rel" ]]; then
        print "  $rel" >> "$TMP_B_ONLY"
    fi
done

# 件数集計
cnt_a_only=$(wc -l < "$TMP_A_ONLY" | tr -d ' ')
cnt_b_only=$(wc -l < "$TMP_B_ONLY" | tr -d ' ')
cnt_diff=$(wc -l < "$TMP_DIFF" | tr -d ' ')

# --- レポート生成 ---
{
    sep="=================================================="
    print "$sep"
    print "ファイル内容差分レポート"
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

    print "[内容が異なる: ${cnt_diff}件]"
    if [[ $cnt_diff -gt 0 ]]; then
        cat "$TMP_DIFF"
    else
        print "  (なし)"
    fi
    print ""

    total=$((cnt_a_only + cnt_b_only + cnt_diff))
    print "$sep"
    print "集計: Aのみ ${cnt_a_only}件 / Bのみ ${cnt_b_only}件 / 内容差異 ${cnt_diff}件 / 合計 ${total}件"
    print "$sep"
} > "$OUTPUT"

cat "$OUTPUT"
print ""
print "レポートを出力しました: $OUTPUT"
