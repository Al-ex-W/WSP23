require 'sinatra'
require 'slim'
require 'sinatra/reloader'
require 'byebug'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/flash' 
enable :sessions
require_relative './model.rb'
include Model # Wat dis?
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

# Before entering any page
# @see Model#admin_check()
# @see Model#user_check()
#
before do
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
#see Model#browsemovies()
get('/') do
    result = browsemovies()
    slim(:"movies/index",locals:{movies:result})
end

# display landing page
#see Model#browsemovies()
get('/movies') do
  result = browsemovies()
  slim(:"movies/index",locals:{movies:result})
end

# Displays page for adding a movie
#
get('/movies/new') do
    slim(:"movies/new")
end


# displays a single movie
# @param [Integer] :movieid, the ID of the movie
#see Model#showmovie()
get('/movies/:movieid') do
  movieid = params[:movieid]
  selectedmovie = showmovie(movieid)
  slim(:"movies/show",locals:{selectedmovie:selectedmovie})
end


# displays edit page for a movie
# @param [Integer] :movieid, the ID of the movie
#see Model#showmovieedit()
get('/movies/:movieid/edit') do
    movieid = params[:movieid]
    movieinfo = showmovieedit(movieid)
    slim(:"movies/edit", locals:{movieinfo:movieinfo})
end

#MOVIES; POST


# Updates an existing movie
# @param [Integer] :movieid, the ID of the movie
# @param [String] :title, the rirle of the movie
# @param [String] :releasedate, the releasedate of the movie
# @see Model#domovieedit()
post('/movies/:movieid/update') do
  title = params[:title]
  releasedate = params[:releasedate]
  movieid = params[:movieid]
  domovieedit(title,releasedate,movieid)
  redirect('/')
end


# Adds new movie
#
# @param [String] :title, the title of the movie
# @param [String] :releasedate, the releasedate of the movie
# @see Model#addnewmovie()
post('/movies') do
  title = params[:title]
  releasedate = params[:releasedate]
  addnewmovie(title,releasedate)
  redirect('/')
end


#REVIEWS

# Displays the reviews page, showing all reviews
#
# @see Model#browsereviews()
get('/reviews') do
  reviewsandusers = browsereviews()
  slim(:"reviews/index",locals:{reviewsandusers:reviewsandusers})
end

# Displays page for writing a review
# @param [Integer] :movieid, the ID of the reviewed movie
#
# @see Model#showreviewadd()
get('/reviews/:movieid/new') do
  movieid = params[:movieid]
  result = showreviewadd(movieid)
  slim(:"reviews/new",locals:{reviewedmovie:result})
end

# Page for displaying a single review
#
# @param [Integer] :reviewid, the ID of the review
# @see Model#showreview
get('/reviews/:reviewid') do
  reviewid = params[:reviewid]
  result = showreview(reviewid)
  slim(:"reviews/show",locals:{selectedreview:result[0], collaborators:result[1], collab_names:result[2]})
end

#Displays edit page for a review
# @param [Integer] :reviewid, the ID of the review
# @see Model#showreviewedit()
get('/reviews/:reviewid/edit') do
  reviewid = params[:reviewid]
  sessionid = session[:id]
  selectedreview = showreviewedit(reviewid,sessionid)
  slim(:"reviews/edit",locals:{selectedreview:selectedreview})
end

#REVIEWS; POST


# Deletes a review
# @param [Integer] :reviewid, the ID of the review
#
# @see Model#doreviewdelete()
post('/reviews/:reviewid/delete') do 
    reviewid = params[:reviewid]
    doreviewdelete(reviewid)
    redirect('/reviews')
end


# Submits a review
#
# @param [Integer] :movieid, the ID of the reviewed movie
# @param [String] :title, the title of the review
# @param [String] :reviewtext, the text of the review
# @param [Integer] :rating, tha rating of the review
# @see Model#doreviewsubmit()
post('/reviews/:movieid') do
  movieid = params[:movieid].to_i
  title = params[:title]
  reviewtext = params[:reviewtext]
  rating = params[:rating]
  user = session[:currentuser]
  sessionid = session[:id]
  doreviewsubmit(movieid,title,reviewtext,rating,user,sessionid)
  redirect('/')
end

# Liking a review
# @param [Integer] :reviewid, the ID of the liked review
#
# @see Model#likereview()
post('/reviews/:reviewid/like') do
  reviewid = params[:reviewid]
  sessionid = session[:id]
  likereview(reviewid,sessionid)
  redirect("reviews/#{reviewid}")
end


# Updates a review
# @param [Integer] :reviewid, the ID of the review
# @param [String] :title, the title of the review
# @param [String] :reviewtext, the text of the review
# @param [Integer] :rating, tha rating of the review
# @param [String] :collaborator, the added collaborator of the review
# @see Model#doreviewupdate()
post('/reviews/:reviewid/update') do
  title = params[:title]
  reviewtext = params[:reviewtext]
  rating = params[:rating]
  user = session[:currentuser]
  collaborator = params[:collaborator]
  sessionid = session[:id]
  reviewid = params[:reviewid]
  doreviewupdate(title,reviewtext,rating,user,collaborator,sessionid,reviewid)
  redirect("/reviews/#{reviewid}")
end

#USERS


# Displays a page showing a single user
# @param [String] :username, the user's name
# @see Model#usershow()
get('/users/:username') do
  username = params[:username]
  userandreviews = usershow(username)
  slim(:"users/show",locals:{userandreviews:userandreviews})
end

#USERS; POST

# Makes a user into an admin
# @param [String] :username, the user's name
# @see Model#addadmin()
post('/users/:username/makeadmin') do
  username = params[:username]
  addadmin(username)
  redirect("/users/#{username}")
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
# @param [String] :username, the user's name
# @param [String] :password, the user's password
# @param [String] :password_confirm, the user's confirmed password
# @see Model#registeruser()
post('/register') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
  registeruser(username,password,password_confirm)
  redirect('/')
end

# Logs in the user
# @param [String] :username, the user's name
# @param [String] :password, the user's password
# @see Model#dologin()
post('/login') do
  username=params[:username]
  password=params[:password]
  result = dologin(username,password)
  session[:id] = result[0]
  session[:currentuser] = result[1]
  session[:perms] = result[2]
  redirect('/')
end
