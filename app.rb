require 'sinatra'
require 'slim'
require 'sinatra/reloader'
require 'byebug'
require 'sqlite3'
require 'bcrypt'
enable :sessions
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

post('/submitreview/:movieid') do 
  #fortsätt här, jag har bara lagt in alla saker från review formen här, du ska lägga till reviewtitle i SQLITE samt fixa db.execute kommandot så att alla värden från formen kommer in korrekt i databasen.
  movieid = params[:movieid]
  title = params[:title]
  reviewtext = params[:reviewtext]
  rating = params[:rating]
  user = session[:currentuser]
  db = SQLite3::Database.new('db/db.db')
  db.execute('INSERT INTO "reviews" (username,pwdigest) VALUES (?,?)',username,password_digest) #här
  redirect('/')


end

post('/doregister') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if (password == password_confirm)
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/db.db')
    db.execute('INSERT INTO "users" (username,pwdigest) VALUES (?,?)',username,password_digest)
    redirect('/')
  else
    "passwords did not match"
  end
  
end

get('/login') do
  slim(:login)
end

get('/movies') do
  db = SQLite3::Database.new("db/db.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM movies")
  p result
  slim(:"movies",locals:{movies:result})



end

get('/writereview/:movieid') do
  movieid = params[:movieid]
  db = SQLite3::Database.new("db/db.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM movies WHERE movieid = #{movieid}")
  slim(:writereview,locals:{reviewedmovie:result})
end


post('/dologin') do
  username=params[:username]
  password=params[:password]
  db = SQLite3::Database.new('db/db.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM users WHERE username = ?",username).first
  if result == nil
    "Usern finns ej"
  else
    pwdigest = result["pwdigest"]
    id = result["id"]
    currentuser = result["username"]
    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      session[:currentuser] = currentuser
      redirect('/')
    else
      "FEL LÖSEN"
    end
  end
end