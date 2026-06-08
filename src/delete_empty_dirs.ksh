#!/bin/ksh
# 空フォルダーを再帰的に削除する

if [ $# -ne 1 ]; then
    echo "使用方法: $0 <対象ディレクトリ>" >&2
    exit 1
fi

TARGET_DIR="$1"

if [ ! -d "${TARGET_DIR}" ]; then
    echo "エラー: ディレクトリが存在しません: ${TARGET_DIR}" >&2
    exit 1
fi

DELETED=0

while true; do
    COUNT=$(find "${TARGET_DIR}" -mindepth 1 -type d -empty | wc -l)
    [ "${COUNT}" -eq 0 ] && break

    find "${TARGET_DIR}" -mindepth 1 -type d -empty | while read -r dir; do
        echo "削除: ${dir}"
        rmdir "${dir}"
    done

    DELETED=$((DELETED + COUNT))
done

echo "完了: ${DELETED} 件の空フォルダーを削除しました"
