#!/bin/ksh
#
# 日付フォルダー内のファイルをBフォルダーへコピーする
# 同名ファイルが存在する場合は上書き前にCフォルダーへバックアップする
# タイムスタンプを保持する（cp -p を使用）
#
# 使用方法: ./copy_date_files.ksh <ソースディレクトリ> <Bフォルダパス> <Cフォルダパス>
#   例: ./copy_date_files.ksh /data/source /data/B /data/C
#

if [[ $# -ne 3 ]]; then
    print "使用方法: $0 <ソースディレクトリ> <Bフォルダパス> <Cフォルダパス>" >&2
    exit 1
fi

SRC_DIR="$1"
DST_DIR="$2"
BCK_DIR="$3"
START_DATE="20201001"
TODAY=$(date +%Y%m%d)

if [[ ! -d "$SRC_DIR" ]]; then
    print "エラー: ソースディレクトリが存在しません: $SRC_DIR" >&2
    exit 1
fi

if [[ ! -d "$DST_DIR" ]]; then
    print "Bフォルダーを作成します: $DST_DIR"
    mkdir -p "$DST_DIR" || {
        print "エラー: Bフォルダーの作成に失敗しました: $DST_DIR" >&2
        exit 1
    }
fi

if [[ ! -d "$BCK_DIR" ]]; then
    print "Cフォルダーを作成します: $BCK_DIR"
    mkdir -p "$BCK_DIR" || {
        print "エラー: Cフォルダーの作成に失敗しました: $BCK_DIR" >&2
        exit 1
    }
fi

copied=0
backed=0
skipped=0

# ファイル名に日付を付加する関数
# 例: report.csv + 20201015 → report_20201015.csv
#     report     + 20201015 → report_20201015
#     .hidden    + 20201015 → .hidden_20201015
make_backup_name() {
    typeset fname="$1"
    typeset datestr="$2"

    case "$fname" in
        .*)
            # ドットファイルは末尾に日付を付加
            print "${fname}_${datestr}"
            ;;
        *.*)
            # 拡張子ありは拡張子の前に日付を挿入
            print "${fname%.*}_${datestr}.${fname##*.}"
            ;;
        *)
            # 拡張子なしは末尾に日付を付加
            print "${fname}_${datestr}"
            ;;
    esac
}

# 8桁数字のディレクトリを走査
for date_dir in "$SRC_DIR"/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]; do
    # グロブが展開されなかった場合はスキップ
    [[ -d "$date_dir" ]] || continue

    dirname=$(basename "$date_dir")

    # 対象範囲チェック: 20201001 以上、今日以下
    [[ $dirname -lt $START_DATE ]] && continue
    [[ $dirname -gt $TODAY ]] && continue

    # ディレクトリ直下のファイルのみコピー（サブディレクトリは対象外）
    for file in "$date_dir"/*; do
        [[ -f "$file" ]] || continue

        fname=$(basename "$file")

        # Bフォルダーに同名ファイルが存在する場合はCフォルダーへバックアップ
        if [[ -f "$DST_DIR/$fname" ]]; then
            backup_name=$(make_backup_name "$fname" "$dirname")
            if cp -p "$DST_DIR/$fname" "$BCK_DIR/$backup_name"; then
                print "バックアップ: $fname → C/$backup_name"
                backed=$((backed + 1))
            else
                print "警告: バックアップ失敗: $DST_DIR/$fname" >&2
                skipped=$((skipped + 1))
                continue
            fi
        fi

        if cp -p "$file" "$DST_DIR/$fname"; then
            print "コピー: $dirname/$fname → B/"
            copied=$((copied + 1))
        else
            print "警告: コピー失敗: $file" >&2
            skipped=$((skipped + 1))
        fi
    done
done

print ""
print "完了: コピー ${copied} 件, バックアップ ${backed} 件, 失敗 ${skipped} 件"
