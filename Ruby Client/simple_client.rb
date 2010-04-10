#!/usr/bin/ruby
# Simple test client

require 'tunage'

class ResponseHandler < TunageDelegate
  def server_connected(server)
    if server.requires_password? then
      print "Please enter your password: "
      pass = gets.chomp
      server.get_authkey_for_password pass
    end
  end
  
  def authkey_response_received(success, server)
    if success == false then
      print "Invalid password. Try again: "
      pass = gets.chomp
      server.get_authkey_for_password pass
    end
  end
  
  def server_ready(server)
    puts "Server ready!"
    server.do_command 'playPause'
  end
end

puts "Instantiating server..."
server = TunageServer.local_server 4242
server.delegate = ResponseHandler.new

puts "Connecting to server..."
server.connect