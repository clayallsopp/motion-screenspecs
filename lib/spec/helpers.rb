module Bacon
  class Context
    def tests_screenshots(screenshot_class)
      describe screenshot_class
        it "should take screenshots" do
          existing_after = screenshot_class.shared.screenshot_groups.last.instance_variable_get("@after_actions")
          screenshot_class.shared.screenshot_groups.last.after do
            existing_after.call

            # resume tests
            resume
          end

          wait_max 120 do
            screenshot_class.start!
          end
        end

        #screenshot_class.shared.screenshot_groups.each do |group|
        #  describe "#{screenshot_class}.#{group.title}" do
        #    it "should match" do
        #      reference_image = UIImage.imageNamed("screenspecs.bundle/references/#{screenshot_class}/#{group.title}.png")

        #    end
        #  end
        #end
      end
    end
  end
end