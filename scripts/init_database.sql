/* CREATING DATABASE AND SCHEMA */
===============================================
/* Script Purpose
This script is to create the Database and Schema

WARNING
It can be run only once. Once the Database and schema is created this script will not run again.
================================================
*/

CREATE DATABASE datawarehouse; -- Creating Database

USE datawarehouse; -- getting into DataBase

CREATE SCHEMA bronze; -- Creating schema
GO -- seperating into blocks

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
