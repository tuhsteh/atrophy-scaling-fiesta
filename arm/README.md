# Selenium builds for ARM

## Builds

Using the Makefile in github:/seleniumhq/docker-selenium,
i personally built these images for linux/arm64.

```bash
# cd ~/code/seleniumhq/docker-selenium
PLATFORM=linux/arm64 make build
```

### A note on GNU/BSD/macOS `make`

The Makefile uses GNU `grep` to find the current version of Docker, 
but it depends on the `-P` option (i.e. apply the Perl-version of Regex), which 
is no longer available in macOS.

To work around this, you can install `grep` from Homebrew.  

```bash
brew install grep
```

Then, change the script that checks the Docker version to use gnu grep (`ggrep`):  

```
diff --git a/<github>:/seleniumhq/docker-selenium/tests/charts/make/chart_check_env.sh b/<github>:/seleniumhq/docker-selenium/tests/charts/make/chart_check_env.sh
--- a/<github>:/seleniumhq/docker-selenium/tests/charts/make/chart_check_env.sh
+++ b/<github>:/seleniumhq/docker-selenium/tests/charts/make/chart_check_env.sh
@@ -4,3 +4,3 @@
REQUIRED_VERSION="24.0.9"
-DOCKER_VERSION=$(docker --version | grep -oP '\d+\.\d+\.\d+')
+DOCKER_VERSION=$(docker --version | ggrep -oP '\d+\.\d+\.\d+')
version_greater_equal() {
```

## Images

| Image Name                   | Tag                 | Image ID     |
|:-----------------------------|:--------------------|:-------------|
| selenium/standalone-docker   | 4.34.0-20250721     | b834e441ab03 | 
| selenium/standalone-firefox  | 4.34.0-20250721     | 521972decbd6 |  
| selenium/standalone-chromium | 4.34.0-20250721     | c63bb4530629 |  
| selenium/node-docker         | 4.34.0-20250721     | d227923869dc |  
| selenium/node-firefox        | 4.34.0-20250721     | 073ea1a93c37 | 
| selenium/node-chromium       | 4.34.0-20250721     | 1edace69b05d |   
| selenium/node-base           | 4.34.0-20250721     | 1dc0f75cf951 | 
| selenium/video               | ffmpeg-7.1-20250721 | 643be557786b |  
| selenium/event-bus           | 4.34.0-20250721     | c8667bf21766 | 
| selenium/session-queue       | 4.34.0-20250721     | 80987588e9e3 |  
| selenium/sessions            | 4.34.0-20250721     | 19086053ed02 | 
| selenium/router              | 4.34.0-20250721     | 35599b328de9 |  
| selenium/distributor         | 4.34.0-20250721     | 41d9d2aa11d4 | 
| selenium/hub                 | 4.34.0-20250721     | 7373edd347d3 |  
| selenium/base                | 4.34.0-20250721     | 0bc9530bdfec | 

## Author
 
 - SeleniumHQ, et al.
 - trs
 - 2025_07_21

