{
  description = "xDrip Android build environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              android_sdk.accept_license = true;
            };
          };

          android = pkgs.androidenv.composeAndroidPackages {
            platformVersions = [ "36" ];
            buildToolsVersions = [ "35.0.0" "36.0.0" ];
            includeEmulator = false;
            includeSystemImages = false;
            includeSources = false;
            includeNDK = false;
            includeCmake = false;
          };

          androidSdk = android.androidsdk;
          sdkRoot = "${androidSdk}/libexec/android-sdk";
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              jdk17_headless
              git
              bash
              unzip
              which
              androidSdk
            ];

            JAVA_HOME = "${pkgs.jdk17_headless}";
            ANDROID_HOME = sdkRoot;
            ANDROID_SDK_ROOT = sdkRoot;

            shellHook = ''
              export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/36.0.0:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
              export GRADLE_OPTS="''${GRADLE_OPTS:-} -Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/36.0.0/aapt2"
              echo "xDrip build shell: Java $(java -version 2>&1 | head -1)"
              echo "Android SDK: $ANDROID_HOME"
              echo "Build with: ./gradlew assembleProdRelease testProdReleaseUnitTest"
            '';
          };
        });
    };
}
