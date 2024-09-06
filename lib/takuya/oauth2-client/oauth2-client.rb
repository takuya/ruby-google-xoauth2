require_relative './callback-web-server'

module Takuya

end
module Takuya
  class OAuth2Client
    # @type [Google::Auth::UserRefreshCredentials]
    @credentials
    # @type [Google::Auth::UserAuthorizer]
    @authorizer
    attr_accessor :token_path, :client_secret_path
    attr_reader :credentials

    def initialize(client_secret_path, token_path, scope = nil)
      @client_secret_path    = client_secret_path
      @token_path            = token_path
      @scope                 = scope || %w[https://mail.google.com/ openid]
      @user_id               = 'default'
      @callback_host         = 'http://localhost:3304'
      @google_auth_client_id = Google::Auth::ClientId.from_file(@client_secret_path)
      @token_storage         = Google::Auth::Stores::FileTokenStore.new(file: @token_path)
      @authorizer            = Google::Auth::UserAuthorizer.new(@google_auth_client_id, @scope, @token_storage)
    end

    # @return [String] A non-nil string.
    def get_user_email_address

      if @scope.find { |e| e.include? 'mail.google.com' }
        email_address = get_gmail_profile
      elsif @scope.find { |e| e.match? Regexp.union([/openid$/, /email$/, /profile$/]) }
        email_address = get_oauth2_profile
      else
        raise 'scope is invalid'
      end
      #
      raise "using token failed." if email_address.nil?
      email_address
    end

    def start_oauth2
      ## Callbackサーバーを起動する
      result_code = start_callback_webserver
      ## ユーザーが認証した後に取れるCodeを認証してTokenを発行する。
      @credentials = @authorizer.get_credentials_from_code(code: result_code, base_url: @callback_host)
      # トークンを保存する（トークン使ってみるテストを兼ねてる）
      @authorizer.store_credentials(get_user_email_address, @credentials)

    end

    def list_stored_address
      yaml = YAML.load_file(@token_path)
      yaml.keys
    end

    def start_dialog
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
      - secret.json : #{@client_secret_path}
      ## このプログラムは、次の保存先を使います。
      - token.yaml  : #{@token_path}

      EOS
      $stdout.print(" READY? >  ")
      $stdin.gets
    end

    protected

    def get_gmail_profile

      @credentials.refresh! if @credentials.expired?
      service               = Google::Apis::GmailV1::GmailService.new
      service.authorization = @credentials
      profile               = service.get_user_profile('me')
      raise "using token failed." unless profile.respond_to?(:email_address)
      profile.email_address
    end

    def get_oauth2_profile
      service               = Google::Apis::Oauth2V2::Oauth2Service.new
      service.authorization = @credentials
      profile               = service.get_userinfo
      profile.email
    end

    def start_callback_webserver
      grant_access_url = @authorizer.get_authorization_url(base_url: @callback_host)
      puts <<-EOS
      ### ############################ ##########
      WebrickServer is waiting at
  
         #{@callback_host}
  
      please open in your browser.  
      #### ########################### ##########
      EOS
      s = OAuthCallbackWebServer.new(URI.parse(CGI.parse(URI.parse(grant_access_url).query)['redirect_uri'][0]))
      s.root_redirect(grant_access_url)
      s.wait_for_response
      code = s.code
      raise "User Canceled OAUTH2 Process." unless code
      code
    end

  end
end