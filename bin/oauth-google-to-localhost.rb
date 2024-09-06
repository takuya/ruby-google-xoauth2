require "google/apis/gmail_v1"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"
require 'webrick'
require "pry"
require 'google-apis-oauth2_v2'

class OAuthCallbackWebServer

  # @return [WEBrick::HTTPServer] srv
  attr_accessor :srv
  attr_accessor :code

  def initialize(addr = 'localhost', port = 80, dir = nil)
    self.srv = WEBrick::HTTPServer.new(
      BindAddress: addr,
      Port:        port,
      :Logger      => WEBrick::Log.new("/dev/null", WEBrick::Log::INFO),
      :AccessLog   => [[File.open("/dev/null", 'w'), WEBrick::AccessLog::COMBINED_LOG_FORMAT]]
    )
    self.add_get_code_handler(dir)
  end

  def root(grant_access_url)
    # @type [WEBrick::HTTPRequest] req
    # @type [WEBrick::HTTPResponse] res
    proc = Proc.new { |req, res|
      res.body   = "<a href='#{grant_access_url}'>Login By Google </a>"
      res.status = 200
    }
    self.srv.mount_proc('/', proc)
  end

  def add_get_code_handler(dir = '/oauth2callback')
    # @type [WEBrick::HTTPRequest] req
    # @type [WEBrick::HTTPResponse] res
    proc = Proc.new { |req, res|
      code       = req.query['code']
      self.code  = code
      res.body   = "oauth finished. your code is #{code}"
      res.status = 200
      self.srv.shutdown
    }
    self.srv.mount_proc(dir, proc)
  end

  def start
    t = Thread.start do
      self.srv.start
    end
    t.join
    { code: self.code }
  end

  def wait_for_response
    self.start
  end

end

def load_env
  default_client_secret_path = File.expand_path(File.dirname(__FILE__) + "/../credentials/client_secret.json")
  default_token_path         = File.expand_path(File.dirname(__FILE__) + "/../credentials/tokens.yaml")

  client_secret_path = ENV['client_secret_path']
  token_path         = ENV['token_path']
  client_secret_path ||= default_client_secret_path
  token_path         ||= default_token_path
  [client_secret_path, token_path]
end

def start_dialog(client_secret_path, token_path)
  $stdout.puts <<-EOS
    ########
    OAUTH2 トークンを作成します。
      #
      # 準備 client_secret/client_id steps.
      # 
      0.  GCP(https://console.cloud.google.com/) にアクセス、プロジェクトを作成
          0.1 プロジェクト作成(https://console.cloud.google.com/cloud-resource-manage).
          0.2 Gmail API をプロジェクトで有効に. (https://console.cloud.google.com/apis/library/gmail.googleapis.com)
              メモ: People APIでメアドが取得可能であるが、今回は使わない。GMailだけメアドが取得可能なため
      1. 認証情報を作成 Credentials(https://console.cloud.google.com/apis/credentials/oauthclient).
      2. OAuth Client をWEBアプリで作成。
      3. JSON(client_secret.json)をダウンロード。secretが含まれてることを確認。
    
      準備ができたら、Clientを作成し、secret.json をダウンロードして保存する。
      
      ## 次のファイルを準備しましたか？
      - secret.json : #{client_secret_path}
      ## このプログラムは、次の保存先を使います。
      - token.yaml  : #{token_path}

  EOS
  $stdout.print(" READY? >  ")
  $stdin.gets
end

def make_authorizer(client_secret_path, token_path)
  ####
  scope      = ['https://mail.google.com/']
  authorizer = Google::Auth::UserAuthorizer.new(
    Google::Auth::ClientId.from_file(client_secret_path),
    scope,
    Google::Auth::Stores::FileTokenStore.new(file: token_path),

  )
  authorizer
end

def start_callback(grant_access_url)

  callback_uri = URI.parse(CGI.parse(URI.parse(grant_access_url).query)['redirect_uri'][0])
  puts <<-EOS
    ### ############################ ##########
    WebrickServer is waiting at

       #{callback_uri.to_s.gsub(callback_uri.path, '')}

    please open in your browser.  
    #### ########################### ##########
  EOS
  s = OAuthCallbackWebServer.new(callback_uri.host, callback_uri.port, callback_uri.path)
  s.root(grant_access_url)
  ret = s.wait_for_response
  raise "User Canceled OAUTH2 Process." unless ret[:code]
  p ret
end

def get_gmail_profile(credentials)
  service               = Google::Apis::GmailV1::GmailService.new
  service.authorization = credentials
  profile               = service.get_user_profile('me')
  profile.email_address
end

def generate_token(client_secret_path, token_path, user_id, callback_host)
  authorizer  = make_authorizer(client_secret_path, token_path)
  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    redirect_host = callback_host
    url           = authorizer.get_authorization_url(base_url: redirect_host)
    result        = start_callback(url)
    credentials   = authorizer.get_credentials_from_code(code: result[:code], base_url: redirect_host)
    email_address = get_gmail_profile(credentials)
    authorizer.store_credentials(email_address, credentials)
    credentials
  else
    puts "###"
    puts "Token is exists. refresh access token."
    credentials.refresh!
  end
  credentials
end

def verify_token_by_access_imap(credentials, token_path)
  user_id = get_gmail_profile(credentials)
  puts "###"
  puts "UserID:#{user_id}"
  puts "AccessToken:#{credentials.access_token}"
  puts "RefreshToken:#{credentials.refresh_token}"
  puts "tokes are saved in #{token_path}"

  puts "####"
  puts "Test Access Gmail Api as User(#{user_id})"
  service                                 = Google::Apis::GmailV1::GmailService.new
  service.client_options.application_name = 'xoauth2'
  service.authorization                   = credentials
  result                                  = service.list_user_labels user_id
  puts "Get Gmail Labels"
  puts "Labels:"
  puts "No labels found" if result.labels.empty?
  result.labels.each { |label| puts "- #{label.name}" }

  $stdout.puts <<-EOS
  ################################################
  Congratulations! 
    
    We can access your account by XOAUTH2.
  
  EOS

end

def main()
  client_secret_path, token_path = load_env
  start_dialog(client_secret_path, token_path)
  credentials = generate_token(client_secret_path, token_path, 'default', 'http://localhost:8080/')
  verify_token_by_access_imap(credentials, token_path)
end

if $0 == __FILE__
  main
end