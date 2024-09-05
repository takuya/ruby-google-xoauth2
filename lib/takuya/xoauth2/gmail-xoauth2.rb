unless defined?(Takuya::XOAuth2)
  raise LoadError, "Please require 'takuya/xoauth2' instead of 'takuya/xoauth2/gmail-xoauth2'"
end

module Net
  module POP3CommandPatch

    ## ruby net-pop3 はxoauth2 に未対応
    # 利用者も少ないしこんな杜撰なモンキーパッチで対応する
    def auth(user, token)
      xoauth2_str = ["user=#{user}\1auth=Bearer #{token}\1\1"].pack('m0')
      auth_cmd = "AUTH XOAUTH2 #{xoauth2_str}"
      check_response_auth(critical { get_response(auth_cmd) })
    end
  end
end

module Takuya::XOAuth2
  class GMailXOAuth2
    class << self
      def smtp(*args)
        obj = GMailXOAuth2.new(*args)
        obj.smtp_by_xoauth2
      end
      def smtp_replay(*args)
        obj = GMailXOAuth2.new(*args)
        obj.smtp_by_xoauth2("smtp-relay.gmail.com", 465)
      end

      def imap(*args)
        obj = GMailXOAuth2.new(*args)
        obj.imap_by_xoauth2
      end
      def pop3(*args)
        obj = GMailXOAuth2.new(*args)
        obj.pop3_by_xoauth2
      end
    end

    def initialize(client_secret_path, token_path, user_id)
      @client_secret_path, @token_path, @user_id = client_secret_path, token_path, user_id

      raise unless File.exists? @client_secret_path
      raise unless File.exists? @token_path
      raise unless (obj = YAML.load(File.read(token_path)))
      raise unless obj.key? user_id

    end

    def client_access_token(user_id)
      scope       = ['https://mail.google.com/']
      authorizer  = Google::Auth::UserAuthorizer.new(
        Google::Auth::ClientId.from_file(@client_secret_path),
        scope,
        Google::Auth::Stores::FileTokenStore.new(file: @token_path)
      )
      credentials = authorizer.get_credentials(user_id)
      raise "#{user_id} not found in tokens.yml " unless credentials
      credentials.refresh! if credentials.expired?
      credentials.access_token
    end

    # @return [Net::SMTP]
    def smtp_by_xoauth2(smtp_server = "smtp.gmail.com", tls_port = 587)
      user  = @user_id
      token = client_access_token(user)
      smtp  = Net::SMTP.new(smtp_server, tls_port)
      smtp.enable_starttls if tls_port == 587
      smtp.enable_tls if tls_port == 465
      smtp.start(smtp_server, user, token, :xoauth2)
      ##
      smtp
    end

    # @return [Net::IMAP]
    def imap_by_xoauth2()
      user  = @user_id
      token = client_access_token(user)
      imap  = Net::IMAP.new('imap.gmail.com', port:993, ssl:true)
      imap.authenticate('XOAUTH2', user, token)
      ##
      imap
    end
    # @return [Net::POP3]
    def pop3_by_xoauth2(host='pop.gmail.com',port=995)
      user  = @user_id
      token = client_access_token(user)
      # patch
      Net::POP3Command.prepend(Net::POP3CommandPatch)
      pop3 = Net::POP3.new(host,port,false)
      pop3.enable_ssl
      pop3.start(user, token)
      ##
      pop3
    end
  end
end


