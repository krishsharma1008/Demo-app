# Uncomment the next line to define a global platform for your project
platform :ios, '16.0'

project 'NimbleEdgeAssistant.app/NimbleEdgeAssistant.xcodeproj'

target 'NimbleEdgeAssistant' do
  # Build pods as static libraries to avoid embedding dynamic frameworks that trigger sandbox errors
  use_frameworks! :linkage => :static

  # DeliteAI SDK - using correct path to iOS SDK
  pod 'DeliteAI', :path => 'sdks/ios/'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['SWIFT_VERSION'] = '5.0'
      # Disable user script sandboxing until CocoaPods resource scripts are updated
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
    end
  end

  # Apply same setting to application target(s)
  installer.aggregate_targets.each do |aggregate_target|
    # Disable for each native target in user project
    aggregate_target.user_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      end
    end
    # Also set on the project-level build configurations
    aggregate_target.user_project.build_configurations.each do |config|
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
    end
    aggregate_target.user_project.save
  end

  # ── [DeliteAI] Copy LLM Assets to Bundle ───────────────────────────────
  app_project = installer.aggregate_targets
                          .map(&:user_project)
                          .find { |p| p.path.to_s.end_with?("NimbleEdgeAssistant.xcodeproj") }

  if app_project
    app_target = app_project.targets.find { |t| t.name == "NimbleEdgeAssistant" }

    if app_target
      # Only add the phase once
      unless app_target.shell_script_build_phases
                       .any? { |p| p.name == "[DeliteAI] Copy LLM Assets" }

        build_phase = app_target.new_shell_script_build_phase("[DeliteAI] Copy LLM Assets")
        build_phase.shell_script = <<-'SCRIPT'
# Copy the on-device model folder into the bundle at build time.
# Everything under Models/llama3/ is copied verbatim.
ASSETS_SRC="${SRCROOT}/NimbleEdgeAssistant/Models/llama3"
ASSETS_DST="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/Models/llama3"

if [ -d "$ASSETS_SRC" ]; then
  echo "[DeliteAI] Copying LLM assets from $ASSETS_SRC to $ASSETS_DST"
  mkdir -p "$(dirname "$ASSETS_DST")"
  rsync -a --delete "$ASSETS_SRC/" "$ASSETS_DST/"
  echo "[DeliteAI] LLM assets copied successfully"
else
  echo "[DeliteAI] Warning: LLM assets not found at $ASSETS_SRC"
fi
SCRIPT
      end

      app_project.save
    end
  end
end
