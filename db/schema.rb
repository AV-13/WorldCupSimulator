# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_31_084157) do
  create_table "coaches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.integer "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_coaches_on_team_id"
  end

  create_table "groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "matches", force: :cascade do |t|
    t.string "away_source"
    t.integer "away_team_id"
    t.datetime "created_at", null: false
    t.integer "group_id"
    t.string "home_source"
    t.integer "home_team_id"
    t.integer "match_number"
    t.string "round"
    t.string "stage"
    t.datetime "updated_at", null: false
    t.index ["away_team_id"], name: "index_matches_on_away_team_id"
    t.index ["group_id"], name: "index_matches_on_group_id"
    t.index ["home_team_id"], name: "index_matches_on_home_team_id"
    t.index ["match_number"], name: "index_matches_on_match_number", unique: true
    t.index ["round"], name: "index_matches_on_round"
  end

  create_table "players", force: :cascade do |t|
    t.date "birth_date"
    t.string "club"
    t.datetime "created_at", null: false
    t.string "first_name"
    t.string "fm_uid"
    t.string "fotmob_id"
    t.integer "grid_col"
    t.integer "grid_row"
    t.boolean "is_starter"
    t.integer "jersey_number"
    t.string "last_name"
    t.string "position"
    t.integer "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_players_on_team_id"
  end

  create_table "predictions", force: :cascade do |t|
    t.integer "away_score"
    t.datetime "created_at", null: false
    t.integer "home_score"
    t.integer "match_id", null: false
    t.integer "simulation_id", null: false
    t.datetime "updated_at", null: false
    t.index ["match_id"], name: "index_predictions_on_match_id"
    t.index ["simulation_id", "match_id"], name: "index_predictions_on_simulation_id_and_match_id", unique: true
    t.index ["simulation_id"], name: "index_predictions_on_simulation_id"
  end

  create_table "simulations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "mode", default: "complete", null: false
    t.string "pseudo"
    t.string "token"
    t.datetime "updated_at", null: false
    t.index ["mode"], name: "index_simulations_on_mode"
    t.index ["token"], name: "index_simulations_on_token", unique: true
  end

  create_table "teams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "group_id", null: false
    t.string "iso_code"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_teams_on_group_id"
  end

  add_foreign_key "coaches", "teams"
  add_foreign_key "matches", "groups"
  add_foreign_key "matches", "teams", column: "away_team_id"
  add_foreign_key "matches", "teams", column: "home_team_id"
  add_foreign_key "players", "teams"
  add_foreign_key "predictions", "matches"
  add_foreign_key "predictions", "simulations"
  add_foreign_key "teams", "groups"
end
