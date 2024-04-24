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




end