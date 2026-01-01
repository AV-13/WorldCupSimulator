#!/usr/bin/env bash
# Build script for Render deployment
# https://render.com/docs/deploy-rails

set -o errexit

bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:migrate
