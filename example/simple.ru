require File.dirname(__FILE__) + "/../lib/thin/async"

class Simple
  def call(env)
    response = Thin::AsyncResponse.new(env)
    
    response << " " * 1024
    
    response << "this is ... "
    EM.add_timer(1) do
      response << "async stuff!"
      response.done
    end
    
    response.finish
  end
end

run Simple.new