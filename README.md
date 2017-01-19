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

`{:plsm, "~> 1.0.0"}`

to deps in your mix.exs and that will download the package for you

## Forthcoming updates

The plan is to add the following features:
  * Support for other databases
  * Primary key support
  * Foreign key support
  * more unit tests

If you have any questions you can reach me via email at jon@dontbreakthebuild.com
