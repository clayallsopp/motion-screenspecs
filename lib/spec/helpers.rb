module Bacon
  class Context
    def tests_screenshots(screenshot_class)
      describe screenshot_class do
        shared_screenshots = screenshot_class.send(:shared)
        shared_screenshots.exitOnComplete = false
        if shared_screenshots.respond_to?("isLoggingEnabled")
          shared_screenshots.loggingEnabled = false
        end
        tolerance = ENV['_motion-screenspecs-tolerance']
        screenshot_timeout = ENV['_motion-screenspecs-screenshot-timeout']
        diff_timeout = ENV['_motion-screenspecs-diff-timeout']

        it "should take screenshots" do
          existing_after = shared_screenshots.screenshot_groups.last.instance_variable_get("@after_actions")
          shared_screenshots.screenshot_groups.last.after do
            existing_after.call if existing_after

            # resume tests
            resume
          end

          screenshot_class.start!
          wait_max screenshot_timeout do

            true.should == true
          end
        end

        shared_screenshots.screenshot_groups.each do |group|
          title = group.instance_variable_get('@title')
          before do
            path_url = shared_screenshots.screenshotsURL

            is_retina = UIScreen.mainScreen.scale != 1.0
            density = is_retina ? "@2x" : ""
            device_prefix = nil

            if UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad
              device_prefix = "ipad"
            elsif UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone
              device_prefix = "iphone#{CGRectGetHeight(UIScreen.mainScreen.bounds).to_i}"
            end

            device_prefix << density

            file_name = "#{device_prefix}-#{NSLocale.currentLocale.localeIdentifier}-#{title}.png"
            path = path_url.URLByAppendingPathComponent(file_name)
            @screenshot_path = path.absoluteString
          end

          describe "#{screenshot_class}.#{title}" do
            it "should be < #{tolerance}% difference" do

              url = NSURL.URLWithString "http://localhost:9678?screenshot_class=#{screenshot_class}&title=#{title}&screenshot_path=#{@screenshot_path}"
              request = NSURLRequest.requestWithURL(url)
              NSURLConnection.sendAsynchronousRequest(request, queue:NSOperationQueue.mainQueue,
                completionHandler:->(ns_url_response, data, error){
                  @response = ns_url_response
                  @data = data
                  resume
              })

              wait_max diff_timeout do
                body = NSString.alloc.initWithData(@data, encoding:NSUTF8StringEncoding)
                @response.statusCode.should.satisfy("was #{body}%") {|object|
                  object == 200
                }
              end
            end
          end
        end
      end
    end
  end
end