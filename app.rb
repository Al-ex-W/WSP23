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
Kunna uppdatera reviews -- > klart men måste kunna cascadea ratingen då den finns i filmtabellen. Kanske borde calca ratingen dynamiskt när man browsar reviews? !KLART! lägg till knapp !fixat!
namnge restful routes !fixat!
beforeblock ?fixat?
säkra upp delete / update fixat
Validera inputs fixat
färdigställ yardoc
frågor
hur ska jag skriva yardoc i model
hur mycket av min app.rb ska vara i model
Beforeblock post?
many to many 2 ggr"

before do
  p "request path info är #{request.path_info}" 
    if request.request_method == 'GET'
      if [%r{^/movies/new$}, %r{^/movies/([^/]+)/edit$}].any? { |path| request.path_info.match?(path) }
        admin_check("/")
      end
      if [%r{^/reviews/([^/]+)/new$}].any? { |path| request.path_info.match?(path) }
        user_check
      end
    elsif request.request_method == 'POST'
      if [%r{^/movies/([^/]+)/update$}, %r{^/movies$}, %r{^/reviews/([^/]+)/delete$}, %r{^/users/([^/]+)/makeadmin$}].any? { |path| request.path_info.match?(path) }
        admin_check("/")
      end
      if [%r{^/reviews/([^/]+)$}, %r{^/reviews/([^/]+)/like$}, %r{^/reviews/([^/]+)/update$}].any? { |path| request.path_info.match?(path) }
        user_check
      end
    end

end

#MOVIES

# display landing page
# @see Model#fetchdb
get('/') do
    $db = fetchdb
    result = $db.execute("SELECT * FROM movies")
    p result
    slim(:"movies/index",locals:{movies:result})
end

# display landing page
# @see Model#fetchdb
get('/movies') do
  $db = fetchdb
  result = $db.execute("SELECT * FROM movies")
  # p result
  slim(:"movies/index",locals:{movies:result})
end

# Displays page for adding a movie
#
get('/movies/new') do
    slim(:"movies/new")
end


# displays a single movie
# @param [Integer] :movieid, the ID of the movie
get('/movies/:movieid') do
  $db = fetchdb
  selectedmovie = $db.execute("SELECT movies.*, reviews.reviewid, reviews.reviewtext, reviews.user, reviews.likes, reviews.title, reviews.rating, users.username, users.pwdigest, users.userid AS user_id, users.perms, movies.movieid AS movie_id
    FROM movies 
    LEFT JOIN reviews ON movies.movieid = reviews.movieid 
    LEFT JOIN users ON reviews.user = users.userid 
    WHERE movies.movieid = ?", params[:movieid])
  p "här är det: #{selectedmovie}"
  slim(:"movies/show",locals:{selectedmovie:selectedmovie})
end


# displays edit page for a movie
# @param [Integer] :movieid, the ID of the movie
#
get('/movies/:movieid/edit') do
    $db = fetchdb
    movieinfo = $db.execute("SELECT * FROM movies WHERE movieid = ?", params[:movieid])
    slim(:"movies/edit", locals:{movieinfo:movieinfo})
end

#MOVIES; POST


# Updates an existing movie
# @param [Integer] :movieid, the ID of the movie
# @see Model#empty_check
post('/movies/:movieid/update') do 
    title = params[:title]
    releasedate = params[:releasedate]
    empty_check([title,releasedate], '/movies/:movieid/update')
    $db = fetchdb
    $db.execute('UPDATE movies SET moviename = ?, releasedate = ? WHERE movieid = ?', title, releasedate, params[:movieid])
    flash[:notice] = "updated movie #{title}"
    redirect('/')
end


# Adds new movie
#
post('/movies') do 
    title = params[:title]
    releasedate = params[:releasedate]
    pop = 0
    empty_check([title,releasedate], '/movies')
    $db = fetchdb
    $db.execute('INSERT INTO "movies" (moviename,releasedate,pop) VALUES (?,?,?)',title,releasedate,pop)
    flash[:notice] = "added movie #{title}"
    redirect('/')
end


#REVIEWS

# Displays the reviews page, showing all reviews
#
get('/reviews') do
  $db = fetchdb
  reviewsandusers = $db.execute("SELECT * FROM reviews INNER JOIN users ON reviews.user = users.userid")
  slim(:"reviews/index",locals:{reviewsandusers:reviewsandusers})
end

# Displays page for writing a review
# @param [Integer] :movieid, the ID of the reviewed movie
#
get('/reviews/:movieid/new') do
  movieid = params[:movieid]
  $db = fetchdb
  result = $db.execute("SELECT * FROM movies WHERE movieid = ?", movieid)
  slim(:"reviews/new",locals:{reviewedmovie:result})
end

# Page for displying a single review
#
# @param [Integer] :reviewid, the ID of the review
# @see Model#review_check
get('/reviews/:reviewid') do
  $db = fetchdb
  $selectedreview = $db.execute("SELECT * FROM reviews INNER JOIN users ON reviews.user = users.userid WHERE reviewid = ?", params[:reviewid])
  collaborators = $db.execute("SELECT userid FROM users_collab_reviews WHERE reviewid= ?", params[:reviewid])
  collab_names =[]
  currentcollabs = []
  if collaborators != []
      collaborators.each do |current_user|
        collab_names << $db.execute("SELECT username FROM users WHERE userid = ?",current_user['userid']).first['username']
        p collab_names
      end
      p collaborators
      collaborators.each do |x|
        currentcollabs << x['userid']
      end
  else
      currentcollabs = []
  end
  review_check
  p "userns id e: #{$selectedreview}"
  p currentcollabs
  p collab_names
  slim(:"reviews/show",locals:{selectedreview:$selectedreview, collaborators:currentcollabs, collab_names:collab_names})
end

#Displays edit page for a review
# @param [Integer] :reviewid, the ID of the review
#
get('/reviews/:reviewid/edit') do
  $db = fetchdb
  selectedreview = $db.execute("SELECT * FROM reviews WHERE reviewid = ?", params[:reviewid])
  collaborators = $db.execute("SELECT userid FROM users_collab_reviews WHERE reviewid = ?", params[:reviewid])
  currentcollabs = []
  p collaborators
  p "PDJFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄ"
  if collaborators != nil
    collaborators.each do |x|
      currentcollabs << x['userid']
    end
  end
  review_check
  if selectedreview[0]['user'] != session[:id] && !currentcollabs.include?(session[:id])
    flash[:notice] = "You are not owner of review with id #{params[:reviewid]}. are you? log in to correct account first"
    redirect("/reviews/#{params[:reviewid]}")
  end
  slim(:"reviews/edit",locals:{selectedreview:selectedreview})
end

#REVIEWS; POST


# Deletes a review
# @param [Integer] :reviewid, the ID of the review
#
post('/reviews/:reviewid/delete') do 
    $db = fetchdb
    $db.execute('DELETE FROM reviews WHERE reviewid = ?',params[:reviewid])
    $db.execute('DELETE FROM users_like_reviews WHERE reviewid = ?',params[:reviewid])
    $db.execute('DELETE FROM users_collab_reviews WHERE reviewid = ?',params[:reviewid])
    flash[:notice] = "deleted review with id #{params[:reviewid]}"
    redirect('/reviews')
end


# Submits a review
#
# @param [Integer] :movieid, the ID of the reviewed movie
# @see Model#empty_check
post('/reviews/:movieid') do
  movieid = params[:movieid].to_i
  title = params[:title]
  reviewtext = params[:reviewtext]
  rating = params[:rating]
  p rating
  user = session[:currentuser]
  likes = 0
  empty_check([title,reviewtext,movieid,rating,user], "/reviews/#{movieid}/new")
  do_log
  movieinfo = $db.execute("SELECT * FROM movies WHERE movieid = ?", movieid)
  p "movieinfo är:#{movieinfo}"
  newpopularity = (movieinfo[0]['pop']).to_i + 1
  if (movieinfo[0]['movierating']) == nil
    movieinfo[0]['movierating'] = 0
  end
  newrating = (((movieinfo[0]['movierating']).to_f * (movieinfo[0]['pop'])) + rating.to_i)/newpopularity
  title = "#{title} - #{movieinfo[0]['moviename']}"
  $db.execute('UPDATE movies SET pop = ?, movierating = ? WHERE movieid = ?', newpopularity, newrating, movieid)
  $db.execute('INSERT INTO "reviews" (movieid,title,reviewtext,rating,user,likes) VALUES (?,?,?,?,?,?)',movieid,title,reviewtext,rating,session[:id],likes)
  redirect('/')
end

# Liking a review
# @param [Integer] :reviewid, the ID of the liked review
#
post('/reviews/:reviewid/like') do

  p "hejhej test test den ska likea nu"
  $db = fetchdb
  likelist = $db.execute("SELECT * FROM users_like_reviews right JOIN reviews ON users_like_reviews.reviewid = reviews.reviewid WHERE reviews.reviewid = ?", params[:reviewid])
  if likelist.empty?
    flash[:notice] = "review does not exist"
    redirect('/reviews')
  else
    if likelist.any? {|hash| hash['userid'] == session[:id]}
      flash[:notice] = "You have already liked this review"
      redirect("reviews/#{params[:reviewid]}") 
    else
      newlikes = (likelist[0]['likes'].to_i) + 1
      $db.execute('UPDATE reviews SET likes = ? WHERE reviewid = ?', newlikes, params[:reviewid])
      $db.execute('INSERT INTO users_like_reviews (userid,reviewid) VALUES (?,?)',session[:id],params[:reviewid])
      redirect("reviews/#{params[:reviewid]}")
    end
  end
end


# Updates a review
# @param [Integer] :reviewid, the ID of the review
#
post('/reviews/:reviewid/update') do
  title = params[:title]
  reviewtext = params[:reviewtext]
  rating = params[:rating]
  user = session[:currentuser]
  collaborator = params[:collaborator]
  empty_check([title,reviewtext,rating], "/reviews/#{params[:reviewid]}/edit")
  rating = rating.to_i
  dolog
  $db.execute("INSERT INTO userlog (userip,time) VALUES (?,?)",request.ip, Time.now.to_i)
  reviewinfo = $db.execute("SELECT * FROM reviews WHERE reviewid = ?", params[:reviewid])
  movieinfo = $db.execute("SELECT * FROM movies WHERE movieid = ?", reviewinfo[0]['movieid'])
  collaborators = $db.execute("SELECT userid FROM users_collab_reviews WHERE reviewid = ?", params[:reviewid])
  currentcollabs = []
  p collaborators
  p "currentcollabscurrentcollabscurrentcollabscurrentcollabscurrentcollabscurrentcollabscurrentcollabscurrentcollabscurrentcollabscurrentcollabscurrentcollabscurrentcollabscurrentcollabscurrencollabscurrentcollabscurrentcollabscurrentcollabscurrentcollabscurrentcollabscurrentcollabscurrentcollabscurrentcollabscurrentcollabscurrentcollabscurrentcollabscurrentcollabscurrentcollabsurrentcollabscurrentcollabscurrentcollabs"
  if collaborators != []
    collaborators.each do |x|
      currentcollabs << x['userid']
    end
  end
  if reviewinfo.empty?
    flash[:notice] = "review does not exist"
    redirect("/reviews")
  elsif reviewinfo[0]['user'] != session[:id] && !currentcollabs.include?(session[:id])
    flash[:notice] = "You are not the owner of this review"
    redirect("/reviews/#{params[:reviewid]}")
  else 
    pop = movieinfo[0]['pop']
    p pop
    oldmovierating = movieinfo[0]['movierating']
    p oldmovierating
    oldreviewrating = reviewinfo[0]['rating']
    p oldreviewrating
    newmovierating = ((((oldmovierating * pop) - oldreviewrating) + rating) / pop)
    if !collaborator.empty?
      collab_id = $db.execute("SELECT userid FROM users WHERE username = ?", collaborator).first
      if collab_id == nil
        flash[:notice] = "Collab user does not exist"
        redirect("/reviews/#{params[:reviewid]}/edit")
      else
        collab_id = collab_id.values
      end
      p collab_id
      p"fudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohududrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohud"
      $db.execute('INSERT INTO users_collab_reviews (userid,reviewid) VALUES (?,?)', collab_id, params[:reviewid])
    end
    $db.execute('UPDATE reviews SET title = ?, reviewtext = ?, rating = ? WHERE reviewid = ?', title, reviewtext, rating, params[:reviewid])
    $db.execute('UPDATE movies SET movierating = ? WHERE movieid = ?', newmovierating, movieinfo[0]['movieid'])
    flash[:notice] = "Updated the review"
    redirect("/reviews/#{params[:reviewid]}")
  end
end

#USERS


# Displays a page showing a single user
# @param [String] :username, the user's name
#
get('/users/:username') do
  $db = fetchdb
  userandreviews = $db.execute("SELECT * FROM users LEFT JOIN reviews ON users.userid = reviews.user WHERE users.username = ?",params[:username])
  if userandreviews[0] == nil
    flash[:notice] = "user \"#{params[:username]}\" Does not exist bruh"
    redirect('/')
  else
    slim(:"users/show",locals:{userandreviews:userandreviews})
  end
end

#USERS; POST

# Makes a user into an admin
# @param [String] :username, the user's name
#
post('/users/:username/makeadmin') do
  $db = fetchdb
  $db.execute("UPDATE users SET perms = 2 WHERE username = ?",params[:username])
  flash[:notice] = "made #{params[:username]} admin!"
  redirect("/users/#{params[:username]}")
end


#OTHER


# Displays register page
#
get('/register') do
  slim(:register)
end


# Displays login page
#
get('/login') do
  slim(:login)
end

# Logs out the user
#
get('/logout') do 
  session.clear
  redirect('/')
end

#OTHER; POST

# Registers a user
# 
post('/register') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
  empty_check([username,password,password_confirm], '/register')
  $db = fetchdb
  users_with_same_name = $db.execute("SELECT * FROM users WHERE username = ?", username)
  if !users_with_same_name.empty?
    flash[:notice] = "username taken"
    redirect("/register")
  end
  if (password == password_confirm)
    password_digest = BCrypt::Password.create(password)
    $db.execute('INSERT INTO "users" (username,pwdigest,perms) VALUES (?,?,?)',username,password_digest,1)
    redirect('/')
  else
    flash[:notice] = "passwords did not match"
    redirect('/register')
  end
  
end

# Logs in the user
post('/login') do
  username=params[:username]
  password=params[:password]
  p password
  empty_check([username,password], '/login')
  do_log
  result = $db.execute("SELECT * FROM users WHERE username = ?",username).first
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
