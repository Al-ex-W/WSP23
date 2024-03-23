require 'sinatra'
require 'slim'
require 'sinatra/reloader'
require 'byebug'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/flash'
enable :sessions
#require_relative './model.rb' 
"modtools, ska kunna:
göra users till admin
lägga till och redigera filmer
ta bort reviews. När man tar bort en review måste man också ta bort alla dokumenterade likes i refernce tablen."


get('/') do
    db = SQLite3::Database.new("db/db.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM movies")
    p result
    slim(:"movies",locals:{movies:result})
  
  
  
end

get('/reviews') do
  db = SQLite3::Database.new('db/db.db')
  db.results_as_hash = true
  allreviews = db.execute("SELECT * FROM reviews")
  allusers = db.execute("SELECT * FROM users")
  slim(:reviews,locals:{allreviews:allreviews, allusers:allusers})
end

get('/user/:username') do
  db = SQLite3::Database.new('db/db.db')
  db.results_as_hash = true
  userinfo = db.execute("SELECT * FROM users WHERE username = ?",params[:username])
  if userinfo[0] == nil
    "user does not exist"
  else
    usersreviews = db.execute("SELECT * FROM reviews WHERE user = ?",userinfo[0]['userid'])
    p "här är userns resviews: #{usersreviews}"
    slim(:browseuser,locals:{userinfo:userinfo, usersreviews:usersreviews})
  end
end

get('/register') do
  slim(:register)
end

post('/writereview/submitreview/:movieid') do 
  if session[:perms] != nil
    movieid = params[:movieid].to_i
    title = params[:title]
    reviewtext = params[:reviewtext]
    rating = params[:rating]
    user = session[:currentuser]
    likes = 0
    db = SQLite3::Database.new('db/db.db')
    db.results_as_hash = true
    movieinfo = db.execute("SELECT * FROM movies WHERE movieid = ?", movieid)
    p "movieinfo är:#{movieinfo}"
    newpopularity = (movieinfo[0]['pop']).to_i + 1
    if (movieinfo[0]['movierating']) == nil
      movieinfo[0]['movierating'] = 0
    end
    newrating = (((movieinfo[0]['movierating']).to_f * (movieinfo[0]['pop'])) + rating.to_i)/newpopularity
    title = "#{title} - #{movieinfo[0]['moviename']}"
    db.execute('UPDATE movies SET pop = ?, movierating = ? WHERE movieid = ?', newpopularity, newrating, movieid)
    db.execute('INSERT INTO "reviews" (movieid,title,reviewtext,rating,user,likes) VALUES (?,?,?,?,?,?)',movieid,title,reviewtext,rating,session[:id],likes)
    redirect('/')
  else
    flash[:notice] = "You must be logged in to do that"
    redirect('/login')
  end
end

post('/doregister') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if (password == password_confirm)
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/db.db')
    db.execute('INSERT INTO "users" (username,pwdigest,perms) VALUES (?,?,?)',username,password_digest,1)
    redirect('/')
  else
    flash[:notice] = "passwords did not match"
    redirect('/register')
  end
  
end

get('/login') do
  slim(:login)
end

post('/like/:reviewid') do
  if session[:perms] != nil
    p "hejhej test test den ska likea nu"
    db = SQLite3::Database.new('db/db.db')
    db.results_as_hash = true
    selectedreview = db.execute("SELECT * FROM reviews WHERE reviewid = ?", params[:reviewid])
    likelist = db.execute("SELECT * FROM users_like_reviews WHERE reviewid = ? AND userid = ?", params[:reviewid], session[:id])
    if likelist.empty?
      newlikes = (selectedreview[0]['likes'].to_i) + 1
      db.execute('UPDATE reviews SET likes = ? WHERE reviewid = ?', newlikes, params[:reviewid])
      db.execute('INSERT INTO users_like_reviews (userid,reviewid) VALUES (?,?)',session[:id],params[:reviewid])
      redirect("review/#{params[:reviewid]}")
    else
      flash[:notice] = "You have already liked this review"
      redirect("review/#{params[:reviewid]}")
    end
  else
    flash[:notice] = "You must be logged in to do that"
    redirect('/login')
  end
end

get('/logout') do 
  session.clear
  redirect('/')
end

get('/review/:reviewid') do
  db = SQLite3::Database.new('db/db.db')
  db.results_as_hash = true
  selectedreview = db.execute("SELECT * FROM reviews WHERE reviewid = ?", params[:reviewid])
  p "userns id e: #{selectedreview[0]['user']}"
  authoruser = db.execute("SELECT * FROM users WHERE userid = ?", selectedreview[0]['user'])
  slim(:"browsereview",locals:{selectedreview:selectedreview, authoruser:authoruser})
end
get('/movies') do
  db = SQLite3::Database.new("db/db.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM movies")
  p result
  slim(:"movies",locals:{movies:result})
end

get('/movies/:movieid') do
  db = SQLite3::Database.new("db/db.db")
  db.results_as_hash = true
  selectedmovie = db.execute("SELECT * FROM movies WHERE movieid = ?", params[:movieid])
  reviews = db.execute("SELECT * FROM reviews WHERE movieid = ?", params[:movieid])
  allusers = db.execute("SELECT * FROM users")
  slim(:"browsemovie",locals:{selectedmovie:selectedmovie, reviews:reviews, allusers:allusers})
end

get('/writereview/:movieid') do
  if session[:perms] != nil
    movieid = params[:movieid]
    db = SQLite3::Database.new("db/db.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM movies WHERE movieid = ?", movieid)
    slim(:writereview,locals:{reviewedmovie:result})
  else
    flash[:notice] = "You must be logged in to do that"
    redirect('/login')
  end
end


post('/dologin') do
  username=params[:username]
  password=params[:password]
  db = SQLite3::Database.new('db/db.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM users WHERE username = ?",username).first
  if result == nil
    flash[:notice] = "No such user"
    redirect('/login')
  else
    pwdigest = result["pwdigest"]
    id = result["userid"]
    currentuser = result["username"]
    perms = result["perms"]
    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      session[:currentuser] = currentuser
      session[:perms] = perms
      redirect('/')
    else
      flash[:notice] = "fel lösen"
      redirect('/login')
    end
  end
end
