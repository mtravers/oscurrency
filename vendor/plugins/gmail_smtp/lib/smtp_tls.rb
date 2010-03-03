require "openssl"
require "net/smtp"

Net::SMTP.class_eval do
	private
	def do_start(helodomain, user, secret, authtype)
		raise IOError, 'SMTP session already started' if @started
          # see http://blog.inspired.no/smtp-error-while-using-gmail-in-rails-271
          if RUBY_VERSION > "1.8.6"
            check_auth_args user, secret if user or secret # for rails 1.8.7
          else
            check_auth_args user, secret, authtype if user or secret # for rails 1.8.6
          end


		sock = timeout(@open_timeout) { TCPSocket.open(@address, @port) }
		@socket = Net::InternetMessageIO.new(sock)
		@socket.read_timeout = 60 #@read_timeout
		@socket.debug_output = STDERR #@debug_output

		check_response(critical { recv_response() })
		do_helo(helodomain)

		raise 'openssl library not installed' unless defined?(OpenSSL)
		starttls
		ssl = OpenSSL::SSL::SSLSocket.new(sock)
		ssl.sync_close = true
		ssl.connect
		@socket = Net::InternetMessageIO.new(ssl)
		@socket.read_timeout = 60 #@read_timeout
		@socket.debug_output = STDERR #@debug_output
		do_helo(helodomain)

		authenticate user, secret, authtype if user
		@started = true
	ensure
		unless @started
			# authentication failed, cancel connection.
			@socket.close if not @started and @socket and not @socket.closed?
			@socket = nil
		end
	end

	def do_helo(helodomain)
		begin
			if @esmtp
				ehlo helodomain
			else
				helo helodomain
			end
		rescue Net::ProtocolError
			if @esmtp
				@esmtp = false
				@error_occured = false
				retry
			end
			raise
		end
	end

	def starttls
		getok('STARTTLS')
	end

	def quit
		begin
			getok('QUIT')
		rescue EOFError
		end
	end
end