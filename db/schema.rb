# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160121130056) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "abstract_trip", primary_key: "ab_trip_id", force: :cascade do |t|
    t.integer "category_id"
    t.integer "start_point"
    t.integer "end_point"
    t.time    "duration"
  end

  create_table "customer", primary_key: "customer_id", force: :cascade do |t|
    t.string  "name",     limit: 60
    t.string  "address",  limit: 60
    t.string  "postcode", limit: 10
    t.string  "email",    limit: 60
    t.integer "user_id"
    t.string  "tel",      limit: 20
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "invoices", primary_key: "invoice_id", force: :cascade do |t|
    t.integer  "supplier_id"
    t.integer  "vehicle_id"
    t.integer  "schedule_id"
    t.integer  "request_id"
    t.float    "offer_price"
    t.string   "status",      limit: 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "message",     limit: 500
  end

# Could not dump table "location" because of following StandardError
#   Unknown type 'geometry(Point,4269)' for column 'point'

  create_table "message", force: :cascade do |t|
    t.string  "table_name", limit: 30
    t.integer "table_id"
    t.string  "article",    limit: 50
    t.string  "content",    limit: 500
  end

  create_table "properties", primary_key: "property_id", force: :cascade do |t|
    t.string "name", limit: 60
    t.string "unit", limit: 5
  end

  create_table "request", primary_key: "request_id", force: :cascade do |t|
    t.integer  "customer_id"
    t.float    "weight"
    t.integer  "goods_type",        limit: 2
    t.float    "height"
    t.float    "length"
    t.float    "capacity"
    t.string   "other_description", limit: 60
    t.integer  "start_point",       limit: 8
    t.integer  "end_point",         limit: 8
    t.string   "status",            limit: 15
    t.integer  "category_id"
    t.datetime "time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "start_point_lat"
    t.decimal  "start_point_long"
    t.decimal  "end_point_lat"
    t.decimal  "end_point_long"
    t.integer  "distance_estimate"
  end

  create_table "schedule", primary_key: "schedule_id", force: :cascade do |t|
    t.time    "estimate_time"
    t.integer "request_id"
  end

  create_table "setting", force: :cascade do |t|
    t.string  "name",  limit: 15
    t.integer "value"
  end

  create_table "spatial_ref_sys", primary_key: "srid", force: :cascade do |t|
    t.string  "auth_name", limit: 256
    t.integer "auth_srid"
    t.string  "srtext",    limit: 2048
    t.string  "proj4text", limit: 2048
  end

  create_table "supplier", primary_key: "supplier_id", force: :cascade do |t|
    t.string  "name",    limit: 60
    t.string  "address", limit: 60
    t.integer "tel",     limit: 8
    t.string  "email",   limit: 60
    t.integer "user_id"
  end

  create_table "trip", id: false, force: :cascade do |t|
    t.integer "trip_id",     limit: 8,  default: "nextval('trip_trip_id_seq'::regclass)", null: false
    t.string  "vehicle_id",  limit: 30,                                                   null: false
    t.integer "ab_trip_id",  limit: 8
    t.integer "schedule_id"
    t.integer "sequent",     limit: 2
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "role"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "v_category_properties", id: false, force: :cascade do |t|
    t.integer "property_id", null: false
    t.integer "category_id", null: false
    t.float   "value"
  end

# Could not dump table "vehicle" because of following StandardError
#   Unknown type 'geometry(Point,4269)' for column 'point'

  create_table "vehicle_category", force: :cascade do |t|
    t.string "name",        limit: 60
    t.string "description", limit: 60
    t.float  "weight"
    t.float  "height"
    t.float  "length"
    t.float  "capacity"
  end

  add_foreign_key "abstract_trip", "location", column: "end_point", primary_key: "location_id", name: "abstract_trip_end_point_fkey"
  add_foreign_key "abstract_trip", "location", column: "start_point", primary_key: "location_id", name: "abstract_trip_start_point_fkey"
  add_foreign_key "abstract_trip", "vehicle_category", column: "category_id", name: "abstract_trip_category_id_fkey"
  add_foreign_key "invoices", "request", primary_key: "request_id", name: "invoice_request_id_fkey"
  add_foreign_key "invoices", "schedule", primary_key: "schedule_id", name: "invoice_schedule_id_fkey"
  add_foreign_key "invoices", "supplier", primary_key: "supplier_id", name: "invoice_supplier_id_fkey"
  add_foreign_key "invoices", "vehicle", primary_key: "vehicle_id", name: "invoice_vehicle_id_fkey"
  add_foreign_key "request", "customer", primary_key: "customer_id", name: "request_cus_id_fkey"
  add_foreign_key "schedule", "request", primary_key: "request_id", name: "schedule_request_id_fkey"
  add_foreign_key "trip", "schedule", primary_key: "schedule_id", name: "trip_schedule_id_fkey"
  add_foreign_key "v_category_properties", "properties", primary_key: "property_id", name: "v_category_properties_property_id_fkey"
  add_foreign_key "v_category_properties", "vehicle_category", column: "category_id", name: "v_category_properties_v_category_id_fkey"
  add_foreign_key "vehicle", "supplier", column: "s_id", primary_key: "supplier_id", name: "vehicle_s_id_fkey"
  add_foreign_key "vehicle", "vehicle_category", column: "category_id", name: "vehicle_category_id_fkey"
end
