class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    self.window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    self.window.backgroundColor = UIColor.whiteColor
    self.window.makeKeyAndVisible

    true
  end
end
