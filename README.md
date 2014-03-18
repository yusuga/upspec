upspec
======================
自分のpodspecでライブラリを管理しているときに、1コマンドでプロジェクトの更新(新しいtagを付けてpush)とpodspecの更新(新しいtagのディレクトリとpodspecを作成)をまとめて行うUNIX実行ファイルです。

使用例(上記フォルダ構成での例)
---
```
├── podspec
    └── project1
        └── 0.0.1
            └── project1.podspec
        └── 0.0.2
            └── project1.podspec        
    └── project2
        └── 0.0.1
            └── project2.podspec
├── project1
└── project2
```

1. project1で必要なcommitを全て済ます
2. project1で`upspec`を実行

`upspec`では以下が実行されます。

1. project1にgit tag 0.0.3を追加
2. project1をgit push
2. podspec/project1/0.0.3/project1.podspecが生成(0.0.2のコピー)
3. podspec/project1/0.0.3/project1.podspecのs.versionを0.0.3に更新
4. podspecをgit push

導入方法
----------------
1. upspec.xcodeprojをビルド
2. `upspec/upspec/Build/Products/Debug/`に`upspec`というUNIX実行ファイルが出来てるのでそれを`/usr/bin/`とかパスが通っているところに適宜置く

オプション
---
-d

    古いpodspecのディレクトリを削除して新しいディレクトリを作成します。
    例えば、0.0.1があった場合には0.0.2を作成後、0.0.1を削除します。
    
License
----------
    Copyright &copy; 2014 Yu Sugawara (https://github.com/yusuga)
    Licensed under the MIT License.

    Permission is hereby granted, free of charge, to any person obtaining a 
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.