source 'https://rubygems.org'

gem 'rspec', '~> 3.13'
gem 'rake', '~> 13.2'

# Deliberately using stdlib Net::HTTP instead of a gem like Faraday: Faraday's
# gemspec has an unbounded runtime dependency on 'json', and no Windows
# (x64-mingw-ucrt) precompiled binary exists for any json gem version on
# rubygems.org - only "ruby" (source, needs a native-extension compile) and
# "java". Bundler always resolves the newest json release and tries to build
# it, which fails on this machine (no MSYS2 toolchain installed), even though
# a perfectly good json 2.7.2 already ships as a default gem with this Ruby
# install. Net::HTTP + the already-bundled 'json' stdlib avoids the whole
# problem instead of requiring a new system-level toolchain install.
