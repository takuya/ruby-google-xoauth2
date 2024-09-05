unless defined?(Takuya::XOAuth2)
  raise LoadError, "Please require 'takuya/xoauth2' instead of 'takuya/xoauth2/gmail-xoauth2'"
end

Takuya::XOAuth2::VERSION = "0.1.0"