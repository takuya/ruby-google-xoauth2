require "google/apis/gmail_v1"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"
require 'webrick'
require "pry"
require 'google-apis-oauth2_v2'
require 'dotenv/load'

def load_env
  default_client_secret_path = File.expand_path(File.dirname(__FILE__) + "/../credentials/client_secret.json")
  default_token_path         = File.expand_path(File.dirname(__FILE__) + "/../credentials/tokens.yaml")

  client_secret_path = ENV['client_secret_path']
  token_path         = ENV['token_path']
  client_secret_path ||= default_client_secret_path
  token_path         ||= default_token_path
  [client_secret_path, token_path]
end

def renew_access_token(client_secret_path, token_path, user_id)
  ####
  scope       = ['https://mail.google.com/']
  authorizer  = Google::Auth::UserAuthorizer.new(
    gcp_client=Google::Auth::ClientId.from_file(client_secret_path),
    scope,
    token_store = Google::Auth::Stores::FileTokenStore.new(file: token_path),
  )
  credentials = authorizer.get_credentials(user_id)
  raise "#{user_id}'s token does not found. " if credentials.nil?
  puts "Token is found. refresh access token."
  credentials.refresh!
  puts "ACCESS_TOKEN has renewed."
  credentials
end

def list_address(token_path)
  yaml = YAML.load_file(token_path)
  yaml.keys
end

def start_dialog(token_path)
  puts "Staring renew access token."
  users   = list_address(token_path)
  address = nil
  until address
    users.each.with_index do |user, idx|
      puts "#{idx + 1}: #{user} "
    end
    puts ""
    $stdout.print("Enter : >  ")
    input = $stdin.gets.strip
    selected = Integer(input)-1 rescue users.size
    address = users[selected]
  end
  address
end

def main()
  client_secret_path, token_path = load_env
  renew_access_token(client_secret_path, token_path, start_dialog(token_path))
end

if $0 == __FILE__
  main
end