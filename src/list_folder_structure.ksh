#!/bin/ksh
#
# 指定フォルダー配下のフォルダー構造を再帰的に調査し、フルパスのリストとして保存する
#
# 使用方法: ./list_folder_structure.ksh <対象フォルダー> [出力ファイル]
#   例: ./list_folder_structure.ksh /data/A
#       ./list_folder_structure.ksh /data/A /tmp/folder_list.txt
#

if [[ $# -lt 1 || $# -gt 2 ]]; then
    print "使用方法: $0 <対象フォルダー> [出力ファイル]" >&2
    exit 1
fi

TARGET_DIR="${1%/}"
OUTPUT="${2:-folder_list_$(date +%Y%m%d_%H%M%S).txt}"

if [[ ! -d "$TARGET_DIR" ]]; then
    print "エラー: 対象フォルダーが存在しません: $TARGET_DIR" >&2
    exit 1
fi

find "$TARGET_DIR" -type d | sort > "$OUTPUT"

count=$(wc -l < "$OUTPUT" | tr -d ' ')

print "完了: ${count} 件のフォルダーを出力しました: $OUTPUT"
