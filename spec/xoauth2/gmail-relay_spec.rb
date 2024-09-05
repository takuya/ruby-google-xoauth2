RSpec.describe "xoauth2認証テスト" do
  ## OAUTH2に必要なデータ
  client_secret_path = ENV['client_secret_path']
  token_path         = ENV['token_path']
  user_id            = ENV['user_id']

  it "[Net::SMTP]を作成（smtp-relay.gmail.com）" do
    ###
    # smtp-relay.gmail.com:25だけでなく、smtp-relay.gmail.com:465が使えるので夢がある。
    # GSuite Legacyはsmtp-relay.gmail.comに認証だけは可能。
    #   メール配送で`relay denied. Invalid credentials for relay for`になる。
    #
    smtp = Takuya::XOAuth2::GMailXOAuth2.smtp_replay(client_secret_path, token_path, user_id)
    res  = smtp.finish
    expect(res.status).to eq '221'
    expect(res.string).to match /gsmtp$/
  end
end
