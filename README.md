# Thin Asynchronous Response API
A nice wrapper around Thin's obscure async callback used to send response body asynchronously.
Which means you can send the response in chunks while allowing Thin to process other requests.

Crazy delicious with em-http-request for file upload, image processing, proxying, etc.

WARNING: You should not use long blocking operations (Net::HTTP or slow shell calls)
         with this as it will prevent the EventMachine event loop from running and
         block all other requests.

## Usage
Inside your Rack app #call(env):

    Thin::AsyncResponse.new(env) do |response|
      response << "this is ... "
      EM.add_timer(1) do
        # This will be sent to the client 1 sec later without blocking other requests.
        response << "async!"
        response.done
      end
    end

See example/ dir for more.

(c) macournoyer