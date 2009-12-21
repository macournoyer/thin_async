module Thin
  unless defined?(DeferrableBody)
    # Based on version from James Tucker <raggi@rubyforge.org>
    class DeferrableBody
      include EM::Deferrable

      def initialize
        @queue = []
      end

      def call(body)
        @queue << body
        schedule_dequeue
      end

      def each(&blk)
        @body_callback = blk
        schedule_dequeue
      end
  
      private
        def schedule_dequeue
          return unless @body_callback
          EM.next_tick do
            next unless body = @queue.shift
            body.each do |chunk|
              @body_callback.call(chunk)
            end
            schedule_dequeue unless @queue.empty?
          end
        end
    end
  end
  
  # Response whos body is sent asynchronously.
  class AsyncResponse
    include Rack::Response::Helpers
    
    Marker = [-1, {}, []].freeze
    
    attr_reader :headers
    attr_accessor :status
    
    def initialize(env, status=200, headers={})
      @callback = env['async.callback']
      @body = DeferrableBody.new
      @status = status
      @headers = headers
      @headers_sent = false
      
      if block_given?
        yield self
        finish
      end
    end
    
    def send_headers
      return if @headers_sent
      @callback.call [@status, @headers, @body]
      @headers_sent = true
    end
    
    def write(body)
      send_headers
      @body.call(body.respond_to?(:each) ? body : [body])
    end
    alias :<< :write
    
    # Tell Thin the response is complete and the connection can be closed.
    def done
      EM.next_tick { @body.succeed }
    end
    
    # Tell Thin the response is gonna be sent asynchronously.
    # The status code of -1 is the magic trick here.
    def finish
      Marker
    end
  end
end