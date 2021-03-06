module HTTP
  class Request
    class Writer
      # CRLF is the universal HTTP delimiter
      CRLF = "\r\n"

      # Types valid to be used as body source
      VALID_BODY_TYPES = [String, NilClass, Enumerable]

      def initialize(socket, body, headers, headline) # rubocop:disable ParameterLists
        @body           = body
        @socket         = socket
        @headers        = headers
        @request_header = [headline]

        validate_body_type!
      end

      # Adds headers to the request header from the headers array
      def add_headers
        @headers.each do |field, value|
          @request_header << "#{field}: #{value}"
        end
      end

      # Stream the request to a socket
      def stream
        send_request_header
        send_request_body
      end

      # Send headers needed to connect through proxy
      def connect_through_proxy
        add_headers
        @socket << join_headers
      end

      # Adds the headers to the header array for the given request body we are working
      # with
      def add_body_type_headers
        if @body.is_a?(String) && !@headers["Content-Length"]
          @request_header << "Content-Length: #{@body.bytesize}"
        elsif @body.is_a?(Enumerable) && "chunked" != @headers["Transfer-Encoding"]
          fail(RequestError, "invalid transfer encoding")
        end
      end

      # Joins the headers specified in the request into a correctly formatted
      # http request header string
      def join_headers
        # join the headers array with crlfs, stick two on the end because
        # that ends the request header
        @request_header.join(CRLF) + (CRLF) * 2
      end

      def send_request_header
        add_headers
        add_body_type_headers

        @socket << join_headers
      end

      def send_request_body
        if @body.is_a?(String)
          @socket << @body
        elsif @body.is_a?(Enumerable)
          @body.each do |chunk|
            @socket << chunk.bytesize.to_s(16) << CRLF
            @socket << chunk << CRLF
          end

          @socket << "0" << CRLF * 2
        end
      end

      private

      def validate_body_type!
        return if VALID_BODY_TYPES.any? { |type| @body.is_a? type }
        fail RequestError, "body of wrong type: #{@body.class}"
      end
    end
  end
end
