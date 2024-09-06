require "google/apis/gmail_v1"
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

  client_secret_path = ENV['client_secret_path']
  token_path         = ENV['token_path']
  client_secret_path ||= default_client_secret_path
  token_path         ||= default_token_path
  [client_secret_path, token_path]
end

# @param client[Takuya::OAuth2Client]
def renew_access_token(client, user_id)
  credentials = client.authorizer.get_credentials(user_id)
  raise "#{user_id}'s token does not found. " if credentials.nil?
  puts "Token is found. refresh access token."
  credentials.refresh!
  puts "ACCESS_TOKEN has renewed."
  credentials
end

def start_dialog(user_address_list)
  puts "Staring renew access token."
  address = nil
  until address
    user_address_list.each.with_index do |user, idx|
      puts "#{idx + 1}: #{user} "
    end
    puts ""
    $stdout.print("Enter : >  ")
    input = $stdin.gets.strip
    selected = Integer(input)-1 rescue users.size
    address = user_address_list[selected]
  end
  address
end

def main()
  client = Takuya::OAuth2Client.new(*load_env)
  renew_access_token(client, start_dialog(client.list_stored_address))
end

if $0 == __FILE__
  main
end