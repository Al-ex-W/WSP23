module Model 
    
    def fetchdb
        db = SQLite3::Database.new("db/db.db")
        db.results_as_hash = true
        return db
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
            flash[:notice] = "review with id #{params[:reviewid]} does not exist"
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
end