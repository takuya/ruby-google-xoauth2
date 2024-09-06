RSpec.describe "xoauth2認証テスト" do
  ## OAUTH2に必要なデータ
  client_secret_path = ENV['client_secret_path']
  token_path         = ENV['token_path']
  user_id            = ENV['user_id']

  it "[Net::SMTP]を作成（shortcut function/STARTTLS 587）" do
    smtp = Takuya::XOAuth2::GMailXOAuth2.smtp(client_secret_path, token_path, user_id)
    res  = smtp.finish
    expect(res.status).to eq '221'
    expect(res.string).to match /gsmtp$/
    Net::SMTP::AuthXoauth2
  end
  it "[Net::SMTP]を作成（shortcut function/SMTPS 465）" do
    obj = Takuya::XOAuth2::GMailXOAuth2.new(client_secret_path, token_path, user_id)
    smtp = obj.smtp_by_xoauth2("smtp.gmail.com", 465)
    res  = smtp.finish
    expect(res.status).to eq '221'
    expect(res.string).to match /gsmtp$/
    Net::SMTP::AuthXoauth2
  end
end
