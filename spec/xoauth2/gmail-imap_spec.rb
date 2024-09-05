
RSpec.describe "xoauth2認証テスト" do
  require 'securerandom'
  ## OAUTH2に必要なデータ
  client_secret_path = ENV['client_secret_path']
  token_path         = ENV['token_path']
  user_id            = ENV['user_id']

  it "[Net::IMAP]を作成（ショートカット）" do
    imap = Takuya::XOAuth2::GMailXOAuth2.imap(client_secret_path, token_path, user_id)
    imap.select('INBOX')
    search_criteria = ['SUBJECT', SecureRandom.uuid, 'FROM', user_id]
    message_ids = imap.search(search_criteria)

    response_logout = imap.logout
    imap.disconnect

    expect(message_ids).to be_empty
    expect(response_logout.name).to eq "OK"
    expect(response_logout.data.text).to match "Success"
    expect(response_logout.data.text).to match "73"
    expect(imap.disconnected?).to be true

  end
end
