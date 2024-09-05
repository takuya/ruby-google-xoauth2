
RSpec.describe "xoauth2認証テスト" do
  require 'securerandom'
  ## OAUTH2に必要なデータ
  client_secret_path = ENV['client_secret_path']
  token_path         = ENV['token_path']
  user_id            = ENV['user_id']

  it "[Net::POP3]を作成（ショートカット）" do
    pop3 = Takuya::XOAuth2::GMailXOAuth2.pop3(client_secret_path, token_path, user_id)
    expect(pop3.mails.empty?).to be false
  end
end
