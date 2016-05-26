#
# Be sure to run `pod lib lint GROCloudStore.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'GROCloudStore'
  s.version          = '0.1.1'
  s.summary          = 'An NSIncrementalStore subclass backed by CloudKit'

  s.description      = <<-DESC
  GROCloudStore provides an NSIncrementalStore subclass that is backed by CloudKit, allowing data to be loaded from the cloud into your Core Data model. GROCloudStore works by augmenting your existing Core Data model.
                       DESC

  s.homepage         = 'https://github.com/andyshep/GROCloudStore'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Andrew Shepard' => 'shep.andy@gmail.com' }
  s.source           = { :git => 'https://github.com/andyshep/GROCloudStore.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'GROCloudStore/**/*'
end
