class OAuthCallbackWebServer

  # @return [WEBrick::HTTPServer] srv
  attr_accessor :srv
  attr_accessor :code

  def initialize(callback_uri="http://localhost:8080/oauth2callback")

    self.srv = WEBrick::HTTPServer.new(
      BindAddress: URI.parse(callback_uri).host,
      Port:        URI.parse(callback_uri).port,
      :Logger      => WEBrick::Log.new("/dev/null", WEBrick::Log::INFO),
      :AccessLog   => [[File.open("/dev/null", 'w'), WEBrick::AccessLog::COMBINED_LOG_FORMAT]]
    )
    self.add_get_code_handler(URI.parse(callback_uri).path)
  end
  def mount_redirect(mount,redirect_uri)
    # @type [WEBrick::HTTPRequest] req
    # @type [WEBrick::HTTPResponse] res
    proc = Proc.new { |req, res|
      res.body   = <<-EOS
      <html>
        <head>
          <meta http-equiv="refresh" content="30; URL='#{redirect_uri}'" />
        </head>
        <body>
          <a href='#{redirect_uri}'>Login By Google </a>
        </body>
      </html>
      EOS
      res.status = 200
    }
    self.srv.mount_proc(mount, proc)

  end

  def root_redirect(redirect_uri)
    mount_redirect('/',redirect_uri)
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
      trap 'INT' do self.srv.shutdown end
      self.srv.start
    end
    t.join
    { code: self.code }
  end

  def wait_for_response
    self.start
  end

end
