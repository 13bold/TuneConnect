=begin rdoc
  =Ruby Client for Tunage
  
  This file provides an implementation of a lightweight Tunage client in Ruby called TunageServer.
  
  ==Usage
  
  To use the Tunage client, simply +require+ the tunage.rb file in your Ruby code, and create a new instance of the TunageServer class. Then, proceed to connect handlers to the client's various callbacks (in true Ruby form). Once your client is prepared, send it a #connect message, and you'll be good to go.

  Commands are sent using the #do_command method. For more information, check out the {Working Draft of the Tunage Protocol}[http://www.mattpat.net/tunage-api.html].
  
  *Note:* Tunage servers communicate via JSON[http://www.json.org], and thus, TunageServer requires the +json+ gem. You can install it by doing the following:
  
    gem install json
=end

=begin rdoc
The TunageServer class represents a remote Tunage server. This is the class that is used to send commands and otherwise communicate with the server.

==Usage Example
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
      # server.do_command 'playPause'
      # do more stuff...
    end
  end
  
  serverURI = URI.parse('http://localhost:4242')
  
  server = TunageServer.new serverURI
  # server = TunageServer.local_server 4242   # does the same thing in this case
  
  server.delegate = ResponseHandler.new

  puts "Connecting to server..."
  server.connect
=end
class TunageServer
  require 'rubygems'
  require 'json'
  require 'net/http'
  require 'digest/md5'
  
  attr_reader :connected, :requiresPassword, :supportsArtwork, :apiVersion
  attr_accessor :delegate, :blocking
  
  @@localServers = {}
  
=begin rdoc
  Creates an instance of a Tunage server connection.
  [+address+] a URI object that points to the entry point of the server.
=end
  def initialize(address)
    @address = address
    
    @connected = false
    @requiresPassword = false
    @supportsArtwork = false
    @suffix = ""
    @apiVersion = 0
    @password = ""
    @authKey = ""
    @blocking = true
    
    @delegate = nil
  end
  
  # Returns the server address as a string with a trailing slash.
  def server_address
    return @address.to_s.gsub(/([^\/])$/, '\1/')
  end
  
  # Call this after you've registered a delegate to the server and are prepared to begin use.
  def connect
    self.do_command 'serverInfo.txt', &self.method(:complete_connection)
  end
  
  # Tell the server to verify the password obtained from the user, and if valid, store an AuthKey to use for future requests.
  def get_authkey_for_password(password)
    password = Digest::MD5.hexdigest(password)
    
    self.do_command 'getAuthKey', {'password' => password}, &self.method(:handle_authkey)
  end
  
  # This is simply a more Ruby convention-conforming accessor for the requiresPassword instance variable.
  def requires_password?
    return @requiresPassword
  end
  
  # This is simply a more Ruby convention-conforming accessor for the connected instance variable.
  def connected?
    return @connected
  end
  
  # Determines whether or not the server is ready for use. This becomes true under the same conditions that cause the server_ready delegate method to be fired.
  def ready?
    return (@connected && ((@requiresPassword && (not @authKey == "")) || (not @requiresPassword)))
  end
  
  # Returns a string representation of the URI for the given command
  def uri_for_command(command, params = {}, includeAuthKey = true)
    uriString = self.server_address + command + @suffix
    
    params['authKey'] = @authKey if (@requiresPassword) && (not @authKey == "")
    
    if not params.empty?
      paramList = []
      params.each {|key, value| paramList << "#{key}=#{value}"}
      uriString += '?' + paramList.join('&')
    end
    
    return uriString
  end
  
=begin rdoc
  Used to send commands to the Tunage server. If a block is given, the response from the server (as a native Ruby object) is handed off to the block for processing upon the completion of the request. Otherwise, the response is returned.
  
  To specify a preexisting method as a handler for the results (must accept a single parameter), use an ampersand to pass it as a block parameter. For example, if I have a method called +myHandler+:
  
    server.do_command 'myCommand', &method(:myHandler)
  
  [+command+] the command part of the URI to send to the server.
  [+params+ (optional)]  a hash of the parameters to send to the server.
  [+asJSON+ (optional)]   when set to true, this parameter tells the client that the response will be a JSON object. As such, the result will automatically be converted to a native Ruby object. If set to false, the response will be returned verbatim.
=end
  def do_command(command, params = {}, asJSON = true, &responseBlock) # :yields: response
    address = self.uri_for_command(command, params)
    
    puts "Non-blocking calls not supported at this time, performing blocking..." if not @blocking
    
    url = URI.parse(address)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.get(url.request_uri)
    }
    response = res.body
    response = JSON.parse(response) unless asJSON == false
    
    if block_given?
      responseBlock.call(response) 
    else
      return response
    end
  end
  
  # Returns a shared server instance pointing to localhost with the specified port (default 4242). This is useful, because it conserves references based on port number-- in other words, there will only ever be one local server object instantiated by this method for a given port.
  def TunageServer.local_server(port = 4242)
    if not @@localServers.has_key?(port) then
      @@localServers[port] = TunageServer.new(URI.parse("http://localhost:#{port}"))
    end
    return @@localServers[port]
  end
  
  # Begin private methods
  private
  def complete_connection(response)
    if response['version'] >= 1 then
      @apiVersion = response['version']
      @suffix = response['suffix']
      @requiresPassword = response['requiresPassword']
      @supportsArtwork = response['supportsArtwork']
      
      @connected = true
      
      @delegate.server_connected(self) if @delegate.respond_to?(:server_connected)
      @delegate.server_ready(self) if (not @requiresPassword) && @delegate.respond_to?(:server_ready)
    else
      puts "This version of the Tunage protocol is not supported."
    end
  end
  
  def handle_authkey(response)
    if not response['authKey'] == false
      @authKey = response['authKey']
      @delegate.authkey_response_received(true, self) if @delegate.respond_to?(:authkey_response_received)
      @delegate.server_ready(self) if @delegate.respond_to?(:server_ready)
    else
      @delegate.authkey_response_received(false, self) if @delegate.respond_to?(:authkey_response_received)
    end
  end
end

# The TunageDelegate class is a shell class for delegates of TunageServer, which should implement a variety of different methods. Delegates of TunageServer do not _have_ to descend from this class, but it is here for your convenience. This is also good to use for debugging purposes.
class TunageDelegate
  # This delegate method is fired as soon as the server is connected. Here, clients should check to see if the server requires a password (server.requires_password?), and if necessary, prompt the user for the password/get the password. Once a password is obtained, it can be passed back into server.get_authkey_for_password.
  def server_connected(server)
    
  end
  
  # This delegate method signals the client that the server is fully connected and ready to go-- no more action is needed on the part of the client to start sending commands (in other words, the server is connected, and either doesn't require a password, or has already received a valid one). If no password is required on the server, this method will be fired immediately after server_connected.
  def server_ready(server)
    
  end
  
  # This delegate method is fired when a response for an authkey request is returned from the server. If the first parameter, success, is false, the client should be aware that the server is not yet usable. It is advisable that the client ask at least twice more for the user's password, perhaps indefinitely if feasible. Once a response of true is received, a server_ready message will also be fired.
  def authkey_response_received(success, server)
    
  end
end