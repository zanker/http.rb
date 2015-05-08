require "forwardable"

module HTTP
  module Timeout
    class Null
      extend Forwardable

      def_delegators :@socket, :close, :closed?

      attr_reader :options, :socket

      def initialize(options = {})
        @options = options
      end

      # Connects to a socket
      def connect(socket_class, host, port)
        @socket = socket_class.open(host, port)
      end

      # Starts a SSL connection on a socket
      def connect_ssl
        @socket.connect
      end

      # Configures the SSL connection and starts the connection
      def start_tls(host, ssl_socket_class, ssl_context)
        @socket = ssl_socket_class.new(socket, ssl_context)
        @socket.sync_close = true if @socket.respond_to? :sync_close=

        connect_ssl

        return unless ssl_context.verify_mode == OpenSSL::SSL::VERIFY_PEER

        @socket.post_connection_check(host)
      end

      # Read from the socket
      def readpartial(size)
        @socket.readpartial(size)
      end

      # Write to the socket
      def write(data)
        @socket << data
      end

      alias_method :<<, :write
    end
  end
end
