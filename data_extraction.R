library(dplyr)
library(lubridate)
library(stringr)
library(stringi)

#########################################################################################
# Data Extraction #######################################################################
#########################################################################################

# Set JAVA_HOME, set max. memory, and load rJava library
Sys.setenv(JAVA_HOME = "C:\\Program Files\\Java\\jre1.8.0_171")
options(java.parameters = "-Xmx2g")
library(rJava)

# Output Java version
.jinit()
print(.jcall("java/lang/System", "S", "getProperty", "java.version"))

# Load RJDBC library
library(RJDBC)

# Get credentials
datamnr <-
  config::get("datamnr", file = "C:\\Users\\PoorJ\\Projects\\config.yml")

# Create connection driver
jdbcDriver <-
  JDBC(driverClass = "oracle.jdbc.OracleDriver", classPath = "C:\\Users\\PoorJ\\Desktop\\ojdbc7.jar")

# Open connection: kontakt---------------------------------------------------------------
jdbcConnection <-
  dbConnect(
    jdbcDriver,
    url = datamnr$server,
    user = datamnr$uid,
    password = datamnr$pwd
  )


# Get SQL scripts
readQuery <-
  function(file)
    paste(readLines(file, warn = FALSE), collapse = "\n")

# Fetch data
query_isd <- readQuery(here::here("SQL", "get_ISD_data.sql"))
t_isd <- dbGetQuery(jdbcConnection, query_isd)

# Close db connection: kontakt
dbDisconnect(jdbcConnection)


# Transformations
t_isd <- t_isd %>% 
  mutate_if(is.character, stringi::stri_trans_general, "Latin-ASCII") %>% 
  mutate(CREATED = ymd_hms(CREATED),
                          TIMESTAMP = ymd_hms(TIMESTAMP),
                          APPLICATION = stringr::str_replace_all(APPLICATION, ";", "/"),
                          APPGROUP = case_when(stringr::str_detect(APPLICATION_GROUP_CONCAT, "/") ~ "Z_Kozos",
                                               TRUE ~ APPLICATION_GROUP_CONCAT),
                          APPSINGLE = case_when(stringr::str_detect(APPLICATION, "/") ~ "Multiple",
                                                TRUE ~ "Single"))



# Export data -------------------------------------------------------------
dir.create(here::here("Data"))

t_isd_pg <- t_isd %>% 
  select(CASE, ACTIVITY, TIMESTAMP, APPLICATION, APPGROUP, APPSINGLE, BUSINESSEVENT_UNIT, ORGANIZATION, CLASSIFICATION)
  
write.table(t_isd_pg, here::here("Data", "t_isd_pg.csv"),
              row.names = FALSE, sep = ";", quote = FALSE)
  
  