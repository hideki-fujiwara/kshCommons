# kshCommons

Korn Shell (ksh) 用の汎用ユーティリティスクリプト集です。
フォルダー比較やファイルコピーなど、日常的なファイル操作を自動化するスクリプトを提供します。

## スクリプト一覧

| スクリプト | 概要 | ドキュメント |
|---|---|---|
| [compare_folders.ksh](src/compare_folders.ksh) | 2つのフォルダーをタイムスタンプ・サイズで再帰的に比較し、差異をレポート出力 | [詳細](docs/compare_folders.md) |
| [compare_folders_content.ksh](src/compare_folders_content.ksh) | 2つのフォルダーをファイル内容（バイト列）で再帰的に比較し、差異をレポート出力 | [詳細](docs/compare_folders_content.md) |
| [copy_date_files.ksh](src/copy_date_files.ksh) | 日付フォルダー内のファイルをコピー先へ転送し、上書き時は自動バックアップ | [詳細](docs/copy_date_files.md) |
| [delete_empty_dirs.ksh](src/delete_empty_dirs.ksh) | 指定フォルダー配下の空フォルダーを再帰的に削除 | [詳細](docs/delete_empty_dirs.md) |
| [list_folder_structure.ksh](src/list_folder_structure.ksh) | 指定フォルダー配下のフォルダー構造を調査し、フルパスのリストとして保存 | [詳細](docs/list_folder_structure.md) |

## 使い方の概要

### フォルダー比較（属性ベース）

```sh
./src/compare_folders.ksh <Aフォルダ> <Bフォルダ> [出力ファイル]
```

タイムスタンプとサイズで比較します。ファイルを読まないため高速です。

### フォルダー比較（内容ベース）

```sh
./src/compare_folders_content.ksh <Aフォルダ> <Bフォルダ> [出力ファイル]
```

ファイルのバイト列を直接比較します。内容の一致を確実に判定したい場合に使用します。

### 日付フォルダーからのファイルコピー

```sh
./src/copy_date_files.ksh <ソースディレクトリ> <Bフォルダパス> <Cフォルダパス>
```

`YYYYMMDD` 形式の日付フォルダーからファイルをコピーし、上書き時は自動でバックアップします。

## 比較スクリプトの使い分け

| | compare_folders.ksh | compare_folders_content.ksh |
|---|---|---|
| 比較方法 | タイムスタンプ＋サイズ | バイト列（内容） |
| 速度 | 高速 | ファイルサイズに依存 |
| 用途 | 差異候補の高速な絞り込み | 内容の確実な一致確認 |

**推奨フロー**: まず `compare_folders.ksh` で高速に候補を絞り、必要に応じて `compare_folders_content.ksh` で内容を確認する。

## 動作環境

- Korn Shell (ksh)
- Linux（GNU stat）または macOS / Solaris（BSD stat）に対応
- 依存コマンド：`find`, `stat`, `cmp`, `cp`, `date`, `mktemp`, `basename`, `mkdir`
