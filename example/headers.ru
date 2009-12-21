require File.dirname(__FILE__) + "/../lib/thin/async"

class Headers
  def call(env)
    response = Thin::AsyncResponse.new(env)
    
    EM.add_timer(1) do
      response.status = 201
      response.headers["X-Muffin-Mode"] = "ACTIVATED!"
      
      # Headers are sent automatically the first time you call response#<<
      # and can't be modified afterwards.
      response.send_headers
      
      response << "done"
      response.done
    end
    
    response.finish
  end
end

run Headers.new