module Model 
    
    def fetchdb
        $db = SQLite3::Database.new("db/db.db")
        $db.results_as_hash = true
        return $db
    end

    def is_checked(i)
        if selectedreview[0]['rating'].to_i == i
            return "checked"
        end
    end

    def admin_check(link)
        if session[:perms] == 1
            flash[:notice] = "you are not facilitated to do that"
            redirect(link)
        elsif session[:perms] == nil
            flash[:notice] = "only admin can do that, are you admin? log in first."
            redirect(link)
        end
    end

    def user_check
        if session[:perms] == nil
            flash[:notice] = "You must be logged in to do that"
            redirect('/login')
        end
    end

    def review_check
        if $selectedreview.empty?
            flash[:notice] = "review with id #{reviewid} does not exist"
            redirect("/reviews")
        end
    end

    def empty_check(list, link)
        list.each do |item|
            if item == nil || item == ""
                flash[:notice] = "You submitted an empty field"
                redirect(link)
            end
        end
    end

    def do_log
        $db = fetchdb
        log = $db.execute("SELECT * FROM userlog WHERE userip = ? AND time > ?",request.ip, (Time.now.to_i - 300))
        if log.count >= 6 && session[:perms] != 2
          $db.execute("INSERT INTO userlog (userip,time) VALUES (?,?)",request.ip, Time.now.to_i)  
          flash[:notice] = "too many website actions, wait some time!"
          redirect('/')
        end
        $db.execute("INSERT INTO userlog (userip,time) VALUES (?,?)",request.ip, Time.now.to_i)
    end

    def browsemovies
        $db = fetchdb
        return $db.execute("SELECT * FROM movies")
    end

    def showmovie(movieid)
        $db = fetchdb
        return $db.execute("SELECT movies.*, reviews.reviewid, reviews.reviewtext, reviews.user, reviews.likes, reviews.title, reviews.rating, users.username, users.pwdigest, users.userid AS user_id, users.perms, movies.movieid AS movie_id
        FROM movies 
        LEFT JOIN reviews ON movies.movieid = reviews.movieid 
        LEFT JOIN users ON reviews.user = users.userid 
        WHERE movies.movieid = ?", movieid)
    end

    def showmovieedit(movieid)
        $db = fetchdb
        return $db.execute("SELECT * FROM movies WHERE movieid = ?", movieid)
    end

    def domovieedit(title,releasedate,movieid)
        empty_check([title,releasedate], '/movies/:movieid/update')
        $db = fetchdb
        $db.execute('UPDATE movies SET moviename = ?, releasedate = ? WHERE movieid = ?', title, releasedate, movieid)
        flash[:notice] = "updated movie #{title}"
    end

    def addnewmovie(title,releasedate)
        pop = 0
        empty_check([title,releasedate], '/movies')
        $db = fetchdb
        $db.execute('INSERT INTO "movies" (moviename,releasedate,pop) VALUES (?,?,?)',title,releasedate,pop)
        flash[:notice] = "added movie #{title}"
    end

    def browsereviews
        $db = fetchdb
        return $db.execute("SELECT * FROM reviews INNER JOIN users ON reviews.user = users.userid")
    end

    def showreviewadd(movieid)
        $db = fetchdb
        return $db.execute("SELECT * FROM movies WHERE movieid = ?", movieid)
    end

    def showreview(reviewid)
        $db = fetchdb
        $selectedreview = $db.execute("SELECT * FROM reviews INNER JOIN users ON reviews.user = users.userid WHERE reviewid = ?", reviewid)
        collaborators = $db.execute("SELECT userid FROM users_collab_reviews WHERE reviewid= ?", reviewid)
        collab_names =[]
        currentcollabs = []
        if collaborators != []
            collaborators.each do |current_user|
              collab_names << $db.execute("SELECT username FROM users WHERE userid = ?",current_user['userid']).first['username']
            end
            collaborators.each do |x|
              currentcollabs << x['userid']
            end
        else
            currentcollabs = []
        end
        review_check
        return [$selectedreview, currentcollabs, collab_names]
    end

    def showreviewedit(reviewid,sessionid)
        $db = fetchdb
        selectedreview = $db.execute("SELECT * FROM reviews WHERE reviewid = ?", reviewid)
        collaborators = $db.execute("SELECT userid FROM users_collab_reviews WHERE reviewid = ?", reviewid)
        currentcollabs = []
        p collaborators
        p "PDJFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄFPIDJFPÄIDHJFOIÄHÄ"
        if collaborators != nil
          collaborators.each do |x|
            currentcollabs << x['userid']
          end
        end
        review_check
        if selectedreview[0]['user'] != sessionid && !currentcollabs.include?(sessionid)
          flash[:notice] = "You are not owner of review with id #{reviewid}. are you? log in to correct account first"
          redirect("/reviews/#{reviewid}")
        end
        return selectedreview
    end

    def doreviewdelete(reviewid)
        $db = fetchdb
        $db.execute('DELETE FROM reviews WHERE reviewid = ?',reviewid)
        $db.execute('DELETE FROM users_like_reviews WHERE reviewid = ?',reviewid)
        $db.execute('DELETE FROM users_collab_reviews WHERE reviewid = ?',reviewid)
        flash[:notice] = "deleted review with id #{reviewid}"
    end

    def doreviewsubmit(movieid,title,reviewtext,rating,user,sessionid)
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
        $db.execute('INSERT INTO "reviews" (movieid,title,reviewtext,rating,user,likes) VALUES (?,?,?,?,?,?)',movieid,title,reviewtext,rating,sessionid,likes)
        flash[:notice] = "Submitted review!"
    end

    def likereview(reviewid,sessionid)
        $db = fetchdb
        likelist = $db.execute("SELECT * FROM users_like_reviews right JOIN reviews ON users_like_reviews.reviewid = reviews.reviewid WHERE reviews.reviewid = ?", reviewid)
        if likelist.empty?
          flash[:notice] = "review does not exist"
          redirect('/reviews')
        else
          if likelist.any? {|hash| hash['userid'] == sessionid}
            flash[:notice] = "You have already liked this review"
            redirect("reviews/#{reviewid}") 
          else
            newlikes = (likelist[0]['likes'].to_i) + 1
            $db.execute('UPDATE reviews SET likes = ? WHERE reviewid = ?', newlikes, reviewid)
            $db.execute('INSERT INTO users_like_reviews (userid,reviewid) VALUES (?,?)',sessionid,reviewid)
          end
        end
    end

    def doreviewupdate(title,reviewtext,rating,user,collaborator,sessionid,reviewid)
        empty_check([title,reviewtext,rating], "/reviews/#{reviewid}/edit")
        rating = rating.to_i
        do_log
        $db.execute("INSERT INTO userlog (userip,time) VALUES (?,?)",request.ip, Time.now.to_i)
        reviewinfo = $db.execute("SELECT * FROM reviews WHERE reviewid = ?", reviewid)
        movieinfo = $db.execute("SELECT * FROM movies WHERE movieid = ?", reviewinfo[0]['movieid'])
        collaborators = $db.execute("SELECT userid FROM users_collab_reviews WHERE reviewid = ?", reviewid)
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
        elsif reviewinfo[0]['user'] != sessionid && !currentcollabs.include?(sessionid)
          flash[:notice] = "You are not the owner of this review"
          redirect("/reviews/#{reviewid}")
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
              redirect("/reviews/#{reviewid}/edit")
            else
              collab_id = collab_id.values
            end
            p collab_id
            p"fudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohududrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohudfudrhfohud"
            $db.execute('INSERT INTO users_collab_reviews (userid,reviewid) VALUES (?,?)', collab_id, reviewid)
          end
          $db.execute('UPDATE reviews SET title = ?, reviewtext = ?, rating = ? WHERE reviewid = ?', title, reviewtext, rating, reviewid)
          $db.execute('UPDATE movies SET movierating = ? WHERE movieid = ?', newmovierating, movieinfo[0]['movieid'])
          flash[:notice] = "Updated the review"
        end
    end

    def usershow(username)
        $db = fetchdb
        userandreviews = $db.execute("SELECT * FROM users LEFT JOIN reviews ON users.userid = reviews.user WHERE users.username = ?",username)
        if userandreviews[0] == nil
          flash[:notice] = "user \"#{username}\" Does not exist bruh"
          redirect('/')
        end
        return userandreviews
    end

    def addadmin(username)
        $db = fetchdb
        $db.execute("UPDATE users SET perms = 2 WHERE username = ?",username)
        flash[:notice] = "made #{username} admin!"
    end

    def registeruser(username,password,password_confirm)
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
        else
          flash[:notice] = "passwords did not match"
          redirect('/register')
        end
    end

    def dologin(username,password)
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
            return [id,currentuser,perms]
          else
            flash[:notice] = "fel lösen"
            redirect('/login')
          end
        end
    end
end