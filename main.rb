require 'lib/monitors/test_http'
require 'lib/ragios'

class TestMySite < TestHttp   
   def initialize
      @time_interval = '1h'
      @contact = "obi@mail.com"	
      @test_description  = "My Website Test"
      @test_url = "http://www.whisperservers.com"  
      super
   end
end

class TestMyBlog < TestHttp 
#tests my blog, to check if the blog is loading

   def initialize
      @time_interval = '1h'
      @contact = "obi@mail.com"
      @test_description  = "My Blog Test"
      @test_url = "http://obi-akubue.homeunix.org/"
      super
   end
end

class TestFakeSite < TestHttp   
#tests a website that doesn't exist this test will always fail
   def initialize
      @time_interval = '1h'
      @contact = "obi@mail.com"
      @test_description  = "Fake website"
      @test_url = "http://wenosee.org/"
      super
   end
end
  

tests = [ TestMySite.new, TestMyBlog.new, TestFakeSite.new]

ragios = Ragios.new tests 
ragios.init
ragios.start

#trap Ctrl-C to exit gracefully
puts "PRESS CTRL-C to QUIT"
  loop do
  trap("INT") { puts "\nExiting"; exit; }
    sleep(3)
  end
