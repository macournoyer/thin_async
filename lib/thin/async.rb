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
    
    def initialize(env)
      @callback = env['async.callback']
      @body = DeferrableBody.new
      @status = 200
      @headers = {}
      
      if block_given?
        yield self
        finish
      end
    end
    
    def write(body)
      @body.call(body.respond_to?(:each) ? body : [body])
    end
    alias :<< :write
    
    def done
      EM.next_tick do
        @body.succeed
      end
    end
    
    def finish
      @callback.call [@status, @headers, @body]
      Marker
    end
  end
end