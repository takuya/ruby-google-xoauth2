## GMail にXOAUTH2でSMTP認証するサンプル

## Installation
Add Following line into Gemfile.

```sh
## Gemfile
URL=https://github.com/takuya/ruby-google-xoauth2.git
echo "gem 'takuya-xoauth2', git: '$URL'" >> Gemfile
```

## Usage Sample
```ruby
require 'dotenv/load'
Dotenv.load('.env', '.env.sample')
## env 
client_secret_path = ENV['client_secret_path'] # must
token_path         = ENV['token_path'] # must
user_id            = ENV['user_id'] # option
## select first of token.
user_id=YAML.load_file(ENV['token_path']).keys[0] if user_id.empty?
## alias
GMailXOAuth2 = Takuya::XOAuth2::GMailXOAuth2

## SMTP
smtp = GMailXOAuth2.smtp(client_secret_path, token_path, user_id)
mail = Mail.new(
  from: user_id, to: 'dummy', subject: 'Test', body: 'Hello.'
)
smtp.sendmail(mail.encoded, user_id, mail.to)

## IMAP 
imap = GMailXOAuth2.imap(client_secret_path, token_path, user_id)
imap.select('INBOX')
uids = imap.uid_search(['SUBJECT','Test', 'FROM', user_id])

## POP3
pop3 = GMailXOAuth2.pop3(client_secret_path, token_path, user_id)
pop3.mails.empty?

```

## OAUTH2 トークンの発行

```ruby
bundle exec ruby bin/oauth-google-to-localhost.rb
```

ENV設定してれば、Enter 連打。ブラウザは自分で開いて。

## OAUTH2 クライアントの準備

1. [GCP](https://console.cloud.google.com/) にアクセス、プロジェクトを作成
1. プロジェクトの設定をする
    - [Gmail API](https://console.cloud.google.com/apis/library/gmail.googleapis.com) をプロジェクトで有効に. 
    - その他、アプリに必要なAPIを有効にする。[People API](https://console.cloud.google.com/apis/library/people.googleapis.com),[Google Drive API](https://console.cloud.google.com/apis/library/drive.googleapis.com)など, 
1. [認証情報一覧](https://console.cloud.google.com/apis/credentials)に移動
1. [認証情報（Credentials）を作成](https://console.cloud.google.com/apis/credentials/oauthclient) .
1. 認証情報の詳細設定をする
    - OAuth2 Client をWEBアプリで作成。
    - 名前を決める
    - コールバックアドレス`"http://localhost:3304/oauth2callback"`を入力して保存。
    - JSON(client_secret.json)をダウンロード。
    - secretが含まれてることを確認。


メモ: APIではメアドやユーザ名が取得可能で動作チェックにも使えるので有効にしている。
xoauth2単体ではPeopleは不要。GMail-APIにてメアドを取得可能なため、Peopleがなくてもメアドが取れる。

メモ：コールバックのアドレスは自由に変えられる。状況に応じた変更後は、[詳細画面](https://console.cloud.google.com/apis/credentials/oauthclient)で変更後のコールバック・アドレスを追加する。


## 注意事項

- GCP が `testing(テスト)`だと 7日でREFRESH_TOKENが無効になる。
- gSuite(google workspace) だと、半永久的REFRESH_TOKENになるはず
- gsuite(google workspace)を持ってない場合、７日毎に再認証が必要



## GMailとOAuthの認証とGoogle Workspaceについて

Google Workspaceだと長過ぎるので以下では、GSuite（旧名）で呼称する。

#### 独自メアドとGoogleアカウント

- 独自ドメインのメアドでGoogleアカウントが作成可能である。
- google workspace契約後は独自ドメインを設定する。

この２つの違いがある。独自ドメインのメアドは、Gsuiteとは限らない。

独自ドメインのGoogleアカウントも存在しうる。


#### OAuthのクライアント

OAuthのクライアント（アプリ）には３種類がある

|OAuth 同意画面設定|役割|
|:-----|:-----|
| INTERNAL | Gsuite(Google Workspace)内部ユーザー対象 |
| EXTERNAL/Testing  | 一般Googlアカウント対象・試行用 |
| EXTERNAL/published |一般Googlアカウント対象・本番用 |


#### GoogleアカウントとGsuiteアカウント
アカウントには大まかに３種類がある

|アカウント|役割|管理者|
|:-----|:-----|:-----|
|GSuiteアカウント | 組織向けユーザー・アカウント| Gsuite契約者|
|GSuiteサービスアカウント| 組織向けプログラム用アカウント |Gsuite契約者|
|Googleアカウント | 一般アカウント(主に@gmail.com) |Google社|


Googleアカウントには独自ドメイン・メアドのGoogleアカウントも存在する。

サービスアカウントはプログラムから使う用である。ドメイン全体のあれこれを行うために作る。

#### InternalとExternal

Gsuiteでアプリを作るとInternal（内部）が選べる


|アカウント| INTERNAL | EXTERNAL/Testing   | EXTERNAL/published |
|:-----|:-----|:-------------------|:-----|
|内部ユーザー      |無期限| ７日(外部扱い)               | 無期限(外部扱い) |
|サービスアカウント |無期限| ７日(外部扱い)              | 無期限(外部扱い) |
|外部ユーザ        | 不可 | ７日(外部扱い)              | 無期限 |

Gsuite以外（一般Googleアカウント）プロジェクトは、Externalのみ作成可能。

GsuiteプロジェクトがExternal（外部）なら、一般Googleアカウントも対象にできる。

Gmailのtesting の場合、**7days** でトークンが無効化される。と一般的に言われている。

[OAuth2 Auth](https://developers.google.com/identity/protocols/oauth2/scopes#oauth2)でログイン機能だけのスコープ指定（userinfo.email、userinfo.profile、openid）なら無制限、[Gmail-API](https://developers.google.com/gmail/api/auth/scopes#scopes)が含まれると７日である。

#### SMTP認証方式とアカウント

SMTPサーバーの認証方式とアカウント

|認証方式 |役割|
|:-----|:-----|
| PASSWORD | ログイン・パスワード |
| APP PASSWORD  | アプリ専用パスワード（2FA有効時) |
| XOAUTH2 | OAUHT2トークンから作成 |
| XOAUTH | OAUHT 1.0 トークンから作成 |

XOAUTHはconsumer_secretを使う方法だが、今どきは使わない。

`XOAUTH`と`XOAUTH2`は別物です。

```ruby
### 次は間違いがち
## ":xoauth", ":xoauth2" の違いに注意。
smtp.start(server, user, token, :xoauth2)
smtp.start(server, user, token, :xoauth)
```

#### 認証方式とアカウント種別

認証方式とGsuiteアカウント

| 認証方式        |PASSWORD|APP PASSWORD| XOAUTH2|
|:------------|:-----|:-----|:-----|
| gsuiteアカウント | 可 | 利用可 | 利用可 |
| Googleアカウント | 不可 | 利用可| 利用可（非実用的） | 

GoogleアカウントをXOAUTH2するには、「審査済」の公開アプリケーションが必要になる。iOSでメールアプリを作って公開して販売するような開発会社が使うのがXOAUTH＋Externalである、一般開発者がちょっと使うには無謀である。というか無益無能である。

Gsuiteアカウントは、アカウント管理責任が「契約者」にある。Googleは「GsuiteもOAUTH2に変えろと」脅してくるが、Google社の脅しは理解不能である。パスワード認証廃止かどうかは契約者が選ぶべきことである。繰り返すがパスワード管理責任者は「契約者」である。Gsuiteアカウントは`SMTPリレー`でメール配信可能なため、メアド≠ユーザであり、リレーのためにXOauth2するのはどうかと思う。


#### GMailのメール配送手段

|方式 |役割|
|:-----|:-----|
| GCP GMail API | API経由でメール送信 |
| SMTP | ログインしてSMTPで配送 |
| SMTP relay  | gserverへリレー配送する。 |

gsuite契約者は、smtp-relay が使える。MTA-MTA転送が利用可能である。

#### メール配送手法とアカウント種別

| 種別/配送         | GMail API | SMTP | SMTP relay    |
|:--------------|:-----|:-----|:--------------|
| gsuite        |利用可 | 利用可| 利用可           |
| gsuite legacy | 利用可 | 不可 | 不可(認証可能・配送不可） | 
| Googleアカウント   | 利用可| 不可 | 不可            | 

SMTP RelayはPostfixなどからGMailを通ってインターネットへグローバル配送する。MTA-MTA通信を通せる。

リレー時はGsuite契約ドメインがenvelope fromであれば、fromメアドは何でも配送可能。つまりユーザー作成せずにメアドを使えるわけです。（良い抜け道かもしれない）
１ユーザー契約あれば複数メアドから配送できる。受信メールはCatch-allなどすれば良いわけです。

smtp-relay.gmail.com:25だけでなく、smtp-relay.gmail.com:465が使えるので夢がある。

gsuite Legacyはsmtp-relay.gmail.comに認証可能だが、メール配送で`relay denied. Invalid credentials for relay for`になり配送は拒否された。

#### XOAUTH2とOAUTH トークン

XOAUTH2 は OAUTH2トークンを以下のような文字列にし、PASSWORDの代わりに使うものである。
```
base64("user=" + userName + "^Aauth=Bearer " + accessToken + "^A^A")
```

ruby のNet::SMTP::Authenticator::AuthXoauth2の実装がシンプルで読みやすい。
```ruby
token = "user=#{user}\1auth=Bearer #{secret}\1\1"
smpt_mesg = "AUTH XOAUTH2 #{base64_encode(token)}"
```

## 参考資料

- https://www.itline.jp/~svx/diary/20230818.html
- https://unix.stackexchange.com/questions/584125/postfix-using-oauth2-authentication-for-relay-host
- https://salsa.debian.org/uwabami/libsasl2-module-xoauth2
- https://github.com/moriyoshi/cyrus-sasl-xoauth2
- https://github.com/tarickb/sasl-xoauth2
- https://takuya-1st.hatenablog.jp/entry/2023/12/27/153000
- https://takuya-1st.hatenablog.jp/entry/2022/03/14/175433


