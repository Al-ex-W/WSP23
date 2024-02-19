require 'sinatra'
require 'slim'
require 'sinatra/reloader'
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

get('/register') do
  slim(:register)
end

post('doregister') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if (password == password_confirm)
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/db.db')
    db.execute('INSERT INTO "users" (username,password) VALUES (?,?)',username,password_digest)
    redirect('/')
  else
    "passwords did not match"
  end
  
end

get('/login') do
  slim(:login)
end


post('/dologin') do
  username=params[:username]
  password=params[:password]
  db = SQLite3::Database.new('db/todo2021.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM users WHERE username = ?",username).first
  pwdigest = result["pwdigest"]
  id = result["id"]
  
  if BCrypt::Password.new(pwdigest) == password
    session[:id] = id
    redirect('/todos')
  else
    "FEL LÖSEN"
  end
end