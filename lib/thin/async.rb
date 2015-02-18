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

    attr_reader :headers, :callback
    attr_accessor :status

    # Creates a instance and yields it to the block given
    # returns the async marker
    def self.perform(*args, &block)
      new(*args, &block).finish
    end

    def initialize(env, status=200, headers={})
      @callback = env['async.callback']
      @close = env['async.close']
      @body = DeferrableBody.new
      @status = status
      @headers = headers
      @headers_sent = false
      @done = false

      if block_given?
        yield self
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
      return if done?
      send_headers
      EM.next_tick { @body.succeed }
      @done = true
    end

    # Tells if the response has already been completed
    def done?
      @done
    end

    # Specify a block to be executed when the response is done
    #
    # Calling this method before the response has completed will cause the
    # callback block to be stored on an internal list.
    # If you call this method after the response is done, the block will
    # be executed immediately.
    #
    def callback &block
      @close.callback(&block)
      self
    end

    # Cancels an outstanding callback to &block if any. Undoes the action of #callback.
    #
    def cancel_callback block
      @close.cancel_callback(block)
    end

    # Tell Thin the response is gonna be sent asynchronously.
    # The status code of -1 is the magic trick here.
    def finish
      Marker
    end
  end
end
