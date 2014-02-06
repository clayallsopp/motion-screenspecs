unless defined?(Motion::Project::Config)
  raise "This file must be required within a RubyMotion project Rakefile."
end

require 'motion-screenshots'
require 'motion-env'

require 'webrick'
require 'chunky_png'
require 'fileutils'
require 'shellwords'

is_spec_mode = Rake.application.top_level_tasks.include?('spec')

if is_spec_mode
  class Motion::Project::Config

    def spec_core_files_with_screenshots
      files = spec_core_files_without_screenshots

      lib_helper = File.join(File.dirname(__FILE__), 'spec', 'helpers.rb')
      files << lib_helper unless files.include?(lib_helper)
      files
    end

    alias_method "spec_core_files_without_screenshots", "spec_core_files"
    alias_method "spec_core_files", "spec_core_files_with_screenshots"
  end

  class Motion::Project::App
    class << self
      def build_with_screenspecs(platform, opts = {})
        unless File.exist?('vendor/Pods/KSScreenshotManager')
          Rake::Task["pod:install"].reenable
          Rake::Task["pod:install"].invoke
        end
        build_without_screenspecs(platform, opts)
      end

      alias_method "build_without_screenspecs", "build"
      alias_method "build", "build_with_screenspecs"
    end
  end
end

module Motion
  module Screenspecs
    PORT = 9678
    TOLERANCE_ENV = '_motion-screenspecs-tolerance'
    SCREENSHOT_TIMEOUT_ENV = '_motion-screenspecs-screenshot-timeout'
    DIFF_TIMEOUT_ENV = '_motion-screenspecs-diff-timeout'

    def self.tolerance
      @tolerance
    end

    def self.set_tolerance(tolerance, config)
      @tolerance = tolerance
      config.env[TOLERANCE_ENV] = tolerance
      tolerance
    end

    def self.set_screenshot_timeout(timeout, config)
      config.env[SCREENSHOT_TIMEOUT_ENV] = timeout
    end

    def self.set_diff_timeout(timeout, config)
      config.env[DIFF_TIMEOUT_ENV] = timeout
    end

    def self.open_failures_at_exit?
      !!@open_failures_at_exit
    end

    def self.open_failures_at_exit=(open)
      @open_failures_at_exit = open
    end

    def self.failures
      @failures ||= []
    end

    def self.screenshots_root(screenshot_class)
      "spec/screenshots/#{screenshot_class}"
    end

    def self.start_server!
      # Start a web server to bounce file paths to-and-from the
      # RubyMotion-CRuby barrier
      @web_server ||= begin
        server = WEBrick::HTTPServer.new(:Port => Motion::Screenspecs::PORT, :Logger => WEBrick::Log.new("/dev/null"), :AccessLog => [])
        server.mount '/', Motion::Screenspecs::Servlet
        at_exit {
          server.shutdown
        }
        Thread.start do
          server.start
        end
        server
      end
    end

    class Servlet < WEBrick::HTTPServlet::AbstractServlet
      def do_GET (request, response)
        if (title = request.query["title"]) &&
            (screenshot_path = request.query["screenshot_path"]) &&
            (screenshot_class = request.query['screenshot_class'])
          screenshot_path.gsub!("file://", "")
          screenshots_root = Motion::Screenspecs.screenshots_root(screenshot_class)
          expectation_path = File.expand_path(File.join(screenshots_root, "expectations", "#{title}.png"))
          result_path = File.expand_path(File.join(screenshots_root, "results", "#{title}.png"))
          failure_path = File.expand_path(File.join(screenshots_root, "failures", "#{title}.png"))
          FileUtils.mkdir_p(File.dirname(failure_path))
          FileUtils.mkdir_p(File.dirname(result_path))

          File.delete(result_path) if File.exists?(result_path)
          temp_result_path = File.join(File.dirname(result_path), File.basename(screenshot_path))
          FileUtils.cp(screenshot_path, File.dirname(result_path))
          FileUtils.mv(temp_result_path, result_path)

          File.delete(failure_path) if File.exists?(failure_path)

          percentage = Motion::Screenspecs::ImageDiff.new.percentage(expectation_path, screenshot_path, failure_path)
          success = percentage < Motion::Screenspecs.tolerance
          response.status = success ? 200 : 400
          response.content_type = "text/plain"
          response.body = "%05.2f" % percentage
        else
          response.status = 404
          response.body = "You did not provide the correct parameters"
        end
      end
    end

    class ImageDiff
      include ChunkyPNG::Color

      # via http://jeffkreeftmeijer.com/2011/comparing-images-and-creating-image-diffs/
      def percentage(image_a, image_b, failure_path)
        images = [
          ChunkyPNG::Image.from_file(image_a),
          ChunkyPNG::Image.from_file(image_b)
        ]

        output = ChunkyPNG::Image.new(images.first.width, images.last.height, WHITE)

        diff = []

        images.first.height.times do |y|
          images.first.row(y).each_with_index do |pixel, x|
            unless pixel == images.last[x,y]
              score = Math.sqrt(
                (r(images.last[x,y]) - r(pixel)) ** 2 +
                (g(images.last[x,y]) - g(pixel)) ** 2 +
                (b(images.last[x,y]) - b(pixel)) ** 2
              ) / Math.sqrt(MAX ** 2 * 3)

              output[x,y] = rgb(
                r(pixel) + r(images.last[x,y]) - 2 * [r(pixel), r(images.last[x,y])].min,
                g(pixel) + g(images.last[x,y]) - 2 * [g(pixel), g(images.last[x,y])].min,
                b(pixel) + b(images.last[x,y]) - 2 * [b(pixel), b(images.last[x,y])].min
              )
              diff << score
            end
          end
        end

        summed = diff.inject {|sum, value| sum + value}
        if summed
          percent = (summed / images.first.pixels.length) * 100
        else
          percent = 0
        end
        if percent >= Motion::Screenspecs.tolerance
          output.save(failure_path)
          Motion::Screenspecs.failures << failure_path
        end
        percent
      end
    end
  end
end

lib_dir_path = File.dirname(File.expand_path(__FILE__))
Motion::Project::App.setup do |app|
  app.files.unshift(Dir.glob(File.join(lib_dir_path, "motion/**/*.rb")))

  Motion::Screenspecs.set_tolerance(5.0, app)
  Motion::Screenspecs.set_screenshot_timeout(120, app)
  Motion::Screenspecs.set_diff_timeout(20, app)
  Motion::Screenspecs.open_failures_at_exit = true

  if is_spec_mode
    app.pods do
      pod 'KSScreenshotManager'
    end

    Motion::Screenspecs.start_server!

    at_exit {
      if Motion::Screenspecs.open_failures_at_exit?
        folder_path = Dir.glob('spec/**/failures').first
        `open #{folder_path.shellescape}` unless Motion::Screenspecs.failures.empty?
      end
    }
  end
end
