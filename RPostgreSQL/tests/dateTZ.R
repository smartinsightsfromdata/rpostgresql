## Test of date and datetime types with time zone
##
## Dirk Eddelbuettel, 21 Oct 2008

## only run this if this env.var is set correctly
if ((Sys.getenv("POSTGRES_USER") != "") &
    (Sys.getenv("POSTGRES_HOST") != "") &
    (Sys.getenv("POSTGRES_DATABASE") != "")) {

    ## try to load our module and abort if this fails
    stopifnot(require(RPostgreSQL))

    ## Force a timezone to make the tests comparable at different locations
    Sys.setenv("TZ"="UTC")
    tt<-as.POSIXct(c("2008-07-01 23:45:16.123+0930","2000-01-02 13:34:05.678+1030"), format="%Y-%m-%d %H:%M:%OS%z")
    print(tt)

    ## load the PostgresSQL driver
    drv <- dbDriver("PostgreSQL")
    ## can't print result as it contains process id which changes  print(summary(drv))

    ## connect to the default db
    con <- dbConnect(drv,
                     user=Sys.getenv("POSTGRES_USER"),
                     password=Sys.getenv("POSTGRES_PASSWD"),
                     host=Sys.getenv("POSTGRES_HOST"),
                     dbname=Sys.getenv("POSTGRES_DATABASE"),
                     port=ifelse((p<-Sys.getenv("POSTGRES_PORT"))!="", p, 5432))


dbTypeTests <- function(con, dateclass="timestamp without time zone", tz="UTC") {
    cat("\n\n**** Trying with ", dateclass, "\n")

    if (dbExistsTable(con, "tempostgrestable"))
        dbRemoveTable(con, "tempostgrestable")

    dbGetQuery(con, paste("create table tempostgrestable (tt ", dateclass, ", zz integer);", sep=""))
    insstring <- '2008-07-01 14:15:16.123+00'
    cat(paste('inserted string 1:', insstring))
    cat("\n")
    dbGetQuery(con, paste("insert into tempostgrestable values('", insstring, "', 1);", sep=""))

#    now <- ISOdatetime(2000,1,2,3,4,5.678)
    insstring <- '2000-01-02 03:04:05.678+00'
    cat(paste('inserted string 2:', insstring))
    cat("\n")
    dbGetQuery(con, paste("insert into tempostgrestable values('", insstring, "', 2);", sep=""))
    tt<-as.POSIXct(c("2008-07-01 23:45:16.123+0930","2000-01-02 13:34:05.678+1030"), format="%Y-%m-%d %H:%M:%OS%z")
    print(tt)

    dbGetQuery(con, paste("SET TIMEZONE TO '", tz, "'", sep=""))

    data <- dbGetQuery(con, "select tt from tempostgrestable;")

    times <- data[,1]
    print(times)
    if(as.double(tt[1]) == as.double(times[1])){
      cat('PASS\n')
    }else{
      cat('FAIL\n')
    }
    if(as.double(tt[2]) == as.double(times[2])){
      cat('PASS\n')
    }else{
      cat('FAIL\n')
    }


    dbRemoveTable(con, "tempostgrestable")
    invisible(NULL)
}
    cat('testing UTC')
    dbTypeTests(con, "timestamp")
    dbTypeTests(con, "timestamp with time zone")
    cat('testing Asia/Tokyo')
    dbTypeTests(con, "timestamp", tz="Asia/Tokyo")
    dbTypeTests(con, "timestamp with time zone", tz="Asia/Tokyo")
    cat('testing Australlia/South')
    dbTypeTests(con, "timestamp", tz="Australia/South")
    dbTypeTests(con, "timestamp with time zone", tz="Australia/South")
    cat('testing America/New_York')
    dbTypeTests(con, "timestamp", tz="America/New_York")
    dbTypeTests(con, "timestamp with time zone", tz="America/New_York")

    dbDisconnect(con)
}else{
    cat("Skip.\n")
}

