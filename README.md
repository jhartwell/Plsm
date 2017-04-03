# Plsm (Formally Plasm)- Ecto model generation

Plsm generates Ecto models based on existing database tables in your database. Currently, Ecto only allows the ability to create migrations that creates new tables/schemas. If you have an existing project that you want to add Ecto support for you would have to hand code the models. This can be tedious for tables that have many columns. 

## Running Plsm

First, in order to run plsm, you need to generate a config file. You do this by running

`mix plsm.config`

This will create a skeleton config file. You will need to make your changes in order to run Plsm succesfully.

Once you have your config file generated then you are ready to run plsm. You do this by running 

`mix plsm`

You are able to change the location of the model file output in the configuration file

## Getting Plsm

You can add 

`{:plsm, "=> 1.1.2"}`

to deps in your mix.exs and that will download the package for you

## Using plsm

To start, you must create a config file. Now you can create one by hand or you can use the command `mix plsm.config` to generate a barebones config. The config is just two keyword lists that are used to access the data.

### Project Section

The project section is used to generate module declarations. The name keyword is the name of the module that you want this schema file generated under while the destination path is the location that you want the output to go.

### Database Section

This section contains all the information needed to connect to your database:
  
  * server -> this is the name of the server that you are connecting to. It can be a DNS name or an IP Address. This needs to be filled in as there are no defaults
  * port -> The port that the database server is listening on. This needs to be provided as there may not be a default for your server
  * database_name -> the name of the database that you are connecting to. This is required.
  * username -> The username that is used to connect. Make sure that there is sufficient privelages to be able to connect, query tables as well as query information schemas on the database. The schema information is used to find the index/keys on each table
  * password -> This is necessary as there is no default nor is there any handling of a blank password currently.
  * type -> This dictates which database vendor you are using. We currently support PostgreSQL and MySQL. If no value is entered then it will default to MySQL.


### Supported Databases
  
  We currently support the following databases:
    * MySQL
    * PostgreSQL

 We are planning to add support to other databases but that has not been implemented yet. Please feel free to contribute commits that add different database vendor support!

If you have any questions you can reach me via email at jon@dontbreakthebuild.com
