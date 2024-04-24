# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'JapaneseLDSQuad' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for JapaneseLDSQuad
  pod 'RealmSwift'
  pod 'IQKeyboardManagerSwift'
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'

  target 'JapaneseLDSQuadTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'JapaneseLDSQuadUITests' do
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "11.0"
    end
  end
end
