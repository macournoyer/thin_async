Gem::Specification.new do |s|
  s.name = "thin_async"
  s.version = "0.3.0"
  s.summary = "A nice wrapper to send response body asynchronously with Thin"
 
  s.author = "Marc-Andre Cournoyer"
  s.email = "macournoyer@gmail.com"
  s.files = Dir["**/*"]
  s.homepage = "http://github.com/macournoyer/thin_async"
  s.require_paths = ["lib"]
 
  s.add_dependency "thin", ">= 1.2.1"
end