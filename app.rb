require 'sinatra'
require 'slim'
require 'byebug'
require 'sqlite3'
require 'bcrypt'
#require_relative './model.rb' 

get('/') do
    db = SQLite3::Database.new("db/db.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM movies")
    p result
    slim(:"movies",locals:{movies:result})
  
  
  
  end