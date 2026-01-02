#!/usr/bin/env bash
# Build script for Render deployment
# https://render.com/docs/deploy-rails

set -o errexit

# Install gems excluding dev/test (no solid_cache/queue/cable)
bundle config set --local without 'development test'
bundle install

bundle exec rails assets:precompile
bundle exec rails assets:clean

# db:prepare runs migrations + seeds if DB is new
# db:seed populates data (idempotent - checks if data exists)
bundle exec rails db:prepare
bundle exec rails db:seed
