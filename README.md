# motion-screenspecs

Test your RubyMotion app regressions using screenshot comparison (similar to [Huxley](https://github.com/facebook/huxley) and [Wraith](https://github.com/BBC-News/wraith)):

```
$ rake spec

AppScreenshots
  - should take screenshots

AppScreenshots.menu
  - should be <= 5.0% difference

AppScreenshots.timeline
  - should be <= 5.0% difference [FAILED - was 10.75%]

Bacon::Error: was 10.75%
    spec.rb:698:in `satisfy:': AppScreenshots.timeline - should be <= 5.0% difference
    spec.rb:438:in `execute_block'
    spec.rb:402:in `run_postponed_block:'
    spec.rb:397:in `resume'

3 specifications (3 requirements), 1 failures, 0 errors
```

![exampke](http://i.imgur.com/OQ0uJPU.png)

(calculated diffs are truer than visual representation)

## Installation

Add this line to your application's Gemfile:

    gem 'motion-screenspecs'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install motion-screenspecs

## Usage

motion-screenspecs works in unison with [motion-screenshots](https://github.com/usepropeller/motion-screenshots). Here are the steps you need to get everything working:

1. Create a subclass of `Motion::Screenshots::Base` (see the [motion-screenshots README](https://github.com/usepropeller/motion-screenshots/blob/master/README.md)).

2. Create the following directory structure:

    ```
    spec/
      screenshots/
        [YourScreenshotSubclass]
          expectations/
            [title of your screenshot].png
            [title of your other screenshot].png
            [etc].png
    ```

    The images in `expectations` are known values for your app. You can take these screenshots manually or using motion-screenshots' `rake screenshots`.

    Failing image diffs will be saved in `spec/screenshots/[YourScreenshotSubclass]/failures`. All results from the latest test are saved to `spec/screenshots/[YourScreenshotSubclass]/results`.
    
3. Add a call to `tests_screenshots` in your specs:

    ```ruby
    describe "Screenshots" do
      tests_screenshots AppScreenshots
    end
    ```

The [sample app](sample) is a complete example with a failing test.

Hats off to [Jeff Kreeftmeijer](http://jeffkreeftmeijer.com/2011/comparing-images-and-creating-image-diffs/) for the image diffing help!

## Configuration

There's a couple of configuration options you can use:

```ruby
Motion::Project::App.setup do |app|
  # Set your tolerance % for image differences
  Motion::Screenspecs.set_tolerance(5.0, app)

  # Set how long the tests will wait for your screenshots to finish
  Motion::Screenspecs.set_screenshot_timeout(120, app)

  # Set how long the tests will wait for a given image to finish diffing
  Motion::Screenspecs.set_diff_timeout(20, app)

  # Set whether or not your failed diffs will open in Finder upon finishing tests
  Motion::Screenspecs.open_failures_at_exit = true
end
```

`rake spec`

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Contact

[Clay Allsopp](http://clayallsopp.com/)
[@clayallsopp](https://twitter.com/clayallsopp)
