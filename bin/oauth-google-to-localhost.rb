require "google/apis/gmail_v1"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"
require 'webrick'
require "pry"
require 'google-apis-oauth2_v2'

require_relative '../lib/takuya/oauth2-client/oauth2-client'

def load_env
  default_client_secret_path = File.expand_path(File.dirname(__FILE__) + "/../credentials/client_secret.json")
  default_token_path         = File.expand_path(File.dirname(__FILE__) + "/../credentials/tokens.yaml")
  #
  client_secret_path = ENV['client_secret_path']
  token_path         = ENV['token_path']
  client_secret_path ||= default_client_secret_path
  token_path         ||= default_token_path
  [client_secret_path, token_path]
end

def try_access_gmail_api(credentials, user_id)

  puts "#### ################"
  puts "#### Test Access Gmail Api as User(#{user_id})"
  puts "#### ################"
  service                                 = Google::Apis::GmailV1::GmailService.new
  service.client_options.application_name = 'xoauth2'
  service.authorization                   = credentials
  result                                  = service.list_user_labels user_id
  puts "Get Gmail Labels"
  puts "Labels:"
  puts "No labels found" if result.labels.empty?
  puts result.labels.map { |label| label.name }.inspect

  $stdout.puts <<-EOS
  ### #############################################
  Congratulations! 
    
    We can access your account by XOAUTH2.
  
  EOS

end

def main

  client = Takuya::OAuth2Client.new(*load_env)
  client.start_dialog
  client.start_oauth2
  user_id     = client.get_user_email_address
  credentials = client.credentials
  token_path  = client.token_path
  ## show result
  puts "#### ################"
  puts "#### OAuth token has retrieved"
  puts "#### ################"
  puts "UserID       : #{user_id}"
  puts "AccessToken  : #{credentials.access_token}"
  puts "RefreshToken : #{credentials.refresh_token}"
  puts "tokes are saved in #{token_path}"
  ## Try Access GmailAPI
  try_access_gmail_api(credentials, user_id)
end

if $0 == __FILE__
  main
end