# BGM Plugin for Paper 1.21

Java版プレイヤー（およびGeyser経由のBedrockプレイヤー）にカスタムBGMを配信するPaperプラグイン。

---

## ディレクトリ構成

```
bgm-plugin/
├── build.gradle.kts
├── settings.gradle.kts
├── java-resourcepack/          ← Javaリソースパック（zipにしてHTTPSで公開する）
│   ├── pack.mcmeta
│   └── assets/minecraft/
│       ├── sounds.json
│       └── sounds/custom/bgm/
│           └── bgm.ogg         ← ★ここにBedrockと同じoggファイルをコピーする
└── src/main/
    ├── java/com/example/bgmplugin/
    │   ├── BgmPlugin.java
    │   ├── BgmManager.java
    │   └── ResourcePackUtil.java
    └── resources/
        ├── plugin.yml
        └── config.yml
```

---

## セットアップ手順

### 1. oggファイルを配置

`java-resourcepack/assets/minecraft/sounds/custom/bgm/bgm.ogg`
にBedrockパックと同じoggファイルをコピーする。

### 2. リソースパックをzip化して公開

```bash
cd java-resourcepack
zip -r ../bgm-java.zip .
```

このzipファイルをHTTPSで公開できるURLに置く。
（例: NASのNginx, GitHub Releases, Cloudflare R2 など）

※ Velocityの背後にあるPaperサーバーでも、リソースパックURLは
　クライアントが直接ダウンロードするため外部からアクセスできるURLが必要。

### 3. SHA-1ハッシュを取得

```bash
sha1sum bgm-java.zip
```

### 4. config.yml を編集

```yaml
resource-pack-url: "https://your-server.com/packs/bgm-java.zip"
resource-pack-sha1: "（上で取得したハッシュ）"
force-resource-pack: true
bgm-duration-seconds: 235   # ★実際の曲の長さ（秒）に合わせる
```

### 5. プラグインをビルド

```bash
./gradlew jar
```

`build/libs/bgm-plugin-1.0.0.jar` が生成されるので
Paperの `plugins/` フォルダに配置してサーバーを再起動。

---

## コマンド

| コマンド | 説明 |
|---|---|
| `/bgmreload` | 設定をリロード（OP権限必要） |
| `/bgmresend [player]` | リソースパックを再送信 |

---

## Geyser（Bedrock）プレイヤーについて

Geyser経由のBedrockプレイヤーは引き続き **既存のBedrockリソースパック** でBGMが流れる。
このプラグインはJavaクライアントのみを対象にしている。

Geyser側でJavaリソースパックが干渉する場合は、
Geyserの `config.yml` で `force-resource-packs: false` を確認すること。

---

## sounds.jsonのキー形式について

`config.yml` の `sound-key` と `sounds.json` のキーは一致させること。

```yaml
# config.yml
sound-key: "custom.bgm"
```

```json
// sounds.json（ドットとコロンの違いに注意）
{
  "custom.bgm": { ... }
}
```

Java版のサウンドキーは `namespace:path` 形式（コロン区切り）が正式だが、
`custom.bgm` のようなドット区切りでも動作する。
