require 'sinatra'
require 'slim'
require 'sinatra/reloader'
require 'byebug'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/flash'
enable :sessions
require_relative './model.rb'
include Model
"
Komplettera:
Kunna uppdatera reviews -- > klart men måste kunna cascadea ratingen då den finns i filmtabellen. Kanske borde calca ratingen dynamiskt när man browsar reviews?
namnge restful routes
beforeblock
säkra upp delete / update"


get('/') do
    db = fetchdb
    result = db.execute("SELECT * FROM movies")
    p result
    slim(:"movies",locals:{movies:result})
  
  
  
end

get('/reviews') do
  db = fetchdb
  reviewsandusers = db.execute("SELECT * FROM reviews INNER JOIN users ON reviews.user = users.userid")
  slim(:reviews,locals:{reviewsandusers:reviewsandusers})
end

get('/makeadmin/:username') do
  if session[:perms] == 2
    db = fetchdb
    db.execute("UPDATE users SET perms = 2 WHERE username = ?",params[:username])
    flash[:notice] = "made #{params[:username]} admin!"
    redirect("/user/#{params[:username]}")
  elsif session[:perms] == 1
    flash[:notice] = "you are not facilitated to do that"
    redirect("/user/#{params[:username]}")
  else
    flash[:notice] = "only admin can do that, are you admin? log in first."
    redirect("/user/#{params[:username]}")
  end
end

get('/deletereview/:reviewid') do 
  if session[:perms] == 2
    db = fetchdb
    db.execute('DELETE FROM reviews WHERE reviewid = ?',params[:reviewid])
    db.execute('DELETE FROM users_like_reviews WHERE reviewid = ?',params[:reviewid])
    flash[:notice] = "deleted review with id #{params[:reviewid]}"
    redirect('/reviews')
  elsif session[:perms] == 1
    flash[:notice] = "you are not facilitated to do that"
    redirect("/review/#{params[:reviewid]}")
  else
    flash[:notice] = "only admin can do that, are you admin? log in first."
    redirect("/review/#{params[:reviewid]}")
  end
end

get('/addmovie') do
  if session[:perms] == 2
    slim(:addmovie)
  elsif session[:perms] == 1
    flash[:notice] = "you are not facilitated to do that"
    redirect("/")
  else
    flash[:notice] = "only admin can do that, are you admin? log in first."
    redirect("/")
  end
end

get('/editmovie/:movieid') do
  if session[:perms] == 2
    db = fetchdb
    movieinfo = db.execute("SELECT * FROM movies WHERE movieid = ?", params[:movieid])
    slim(:editmovie, locals:{movieinfo:movieinfo})
  elsif session[:perms] == 1
    flash[:notice] = "you are not facilitated to do that"
    redirect("/")
  else
    flash[:notice] = "only admin can do that, are you admin? log in first."
    redirect("/")
  end
end

post('/doeditmovie/:movieid') do 
  if session[:perms] == 2
    title = params[:title]
    releasedate = params[:releasedate]
    db = fetchdb
    db.execute('UPDATE movies SET moviename = ?, releasedate = ? WHERE movieid = ?', title, releasedate, params[:movieid])
    flash[:notice] = "updated movie #{title}"
    redirect('/')
  elsif session[:perms] == 1
    flash[:notice] = "you are not facilitated to do that"
    redirect('/')
  else
    flash[:notice] = "only admin can do that, are you admin? log in first."
    redirect('/')
  end
end

post('/submitmovie') do 
  if session[:perms] == 2
    title = params[:title]
    releasedate = params[:releasedate]
    pop = 0
    db = fetchdb
    db.execute('INSERT INTO "movies" (moviename,releasedate,pop) VALUES (?,?,?)',title,releasedate,pop)
    flash[:notice] = "added movie #{title}"
    redirect('/')
  elsif session[:perms] == 1
    flash[:notice] = "you are not facilitated to do that"
    redirect('/')
  else
    flash[:notice] = "only admin can do that, are you admin? log in first."
    redirect('/')
  end
end



get('/user/:username') do
  db = fetchdb
  userandreviews = db.execute("SELECT * FROM users LEFT JOIN reviews ON users.userid = reviews.user WHERE users.username = ?",params[:username])
  if userandreviews[0] == nil
    flash[:notice] = "user \"#{params[:username]}\" Does not exist bruh"
    redirect('/')
  else
    slim(:browseuser,locals:{userandreviews:userandreviews})
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
    db = fetchdb
    log = db.execute("SELECT * FROM userlog WHERE userip = ? AND time > ?",request.ip, (Time.now.to_i - 300))
    if log.count >= 5 && session[:perms] < 2
      flash[:notice] = "too many review attempts"
      redirect('/')
    else
      db.execute("INSERT INTO userlog (userip,time) VALUES (?,?)",request.ip, Time.now.to_i)
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
    end
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
    db = fetchdb
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
    db = fetchdb
    likelist = db.execute("SELECT * FROM users_like_reviews right JOIN reviews ON users_like_reviews.reviewid = reviews.reviewid WHERE reviews.reviewid = ?", params[:reviewid])
    if likelist.empty?
      flash[:notice] = "review does not exist"
      redirect('/reviews')
    else
      if likelist.any? {|hash| hash['userid'] == session[:id]}
        flash[:notice] = "You have already liked this review"
        redirect("review/#{params[:reviewid]}") 
      else
        newlikes = (likelist[0]['likes'].to_i) + 1
        db.execute('UPDATE reviews SET likes = ? WHERE reviewid = ?', newlikes, params[:reviewid])
        db.execute('INSERT INTO users_like_reviews (userid,reviewid) VALUES (?,?)',session[:id],params[:reviewid])
        redirect("review/#{params[:reviewid]}")
      end
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
  db = fetchdb
  selectedreview = db.execute("SELECT * FROM reviews INNER JOIN users ON reviews.user = users.userid WHERE reviewid = ?", params[:reviewid])
  p "userns id e: #{selectedreview}"
  slim(:"browsereview",locals:{selectedreview:selectedreview})
end

get('/review/:reviewid/edit') do
  db = fetchdb
  selectedreview = db.execute("SELECT * FROM reviews WHERE reviewid = ?", params[:reviewid])
  p selectedreview
  p "här va det !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!v"
  slim(:"editreview",locals:{selectedreview:selectedreview})
end

post('/review/:reviewid/edit') do
  if session[:perms] != nil
    title = params[:title]
    reviewtext = params[:reviewtext]
    rating = params[:rating]
    user = session[:currentuser]
    db = fetchdb
    log = db.execute("SELECT * FROM userlog WHERE userip = ? AND time > ?",request.ip, (Time.now.to_i - 300))
    if log.count >= 60 && session[:perms] != 2
      flash[:notice] = "too many review edit attempts"
      redirect('/')
    else
      db.execute("INSERT INTO userlog (userip,time) VALUES (?,?)",request.ip, Time.now.to_i)
      reviewinfo = db.execute("SELECT * FROM reviews WHERE reviewid = ?", params[:reviewid])
      if reviewinfo.empty?
        flash[:notice] = "review does not exist"
        redirect("/reviews")
      elsif reviewinfo[0]['user'] != session[:id]
        flash[:notice] = "You are not the owner of this review"
        redirect("/review/#{params[:reviewid]}")
      else
        db.execute('UPDATE reviews SET title = ?, reviewtext = ?, rating = ? WHERE reviewid = ?', title, reviewtext, rating, params[:reviewid])
        flash[:notice] = "Updated the review"
        redirect("/review/#{params[:reviewid]}")
      end
    end
  else
    flash[:notice] = "You must be logged in to do that"
    redirect('/login')
  end
end


get('/movies') do
  db = fetchdb
  result = db.execute("SELECT * FROM movies")
  # p result
  slim(:"movies",locals:{movies:result})
end

get('/movies/:movieid') do
  db = fetchdb
  selectedmovie = db.execute("SELECT movies.*, reviews.reviewid, reviews.reviewtext, reviews.user, reviews.likes, reviews.title, reviews.rating, users.username, users.pwdigest, users.userid AS user_id, users.perms, movies.movieid AS movie_id
    FROM movies 
    LEFT JOIN reviews ON movies.movieid = reviews.movieid 
    LEFT JOIN users ON reviews.user = users.userid 
    WHERE movies.movieid = ?", params[:movieid])
  p "här är det: #{selectedmovie}"
  slim(:"browsemovie",locals:{selectedmovie:selectedmovie})
end

get('/writereview/:movieid') do
  if session[:perms] != nil
    movieid = params[:movieid]
    db = fetchdb
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
  db = fetchdb
  log = db.execute("SELECT * FROM userlog WHERE userip = ? AND time > ?",request.ip, (Time.now.to_i - 300))
  if log.count >= 5
    flash[:notice] = "too many login attempts"
    redirect('/login')
  else
    db.execute("INSERT INTO userlog (userip,time) VALUES (?,?)",request.ip, Time.now.to_i)
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
end
