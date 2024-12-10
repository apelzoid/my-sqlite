# Welcome to My SQlite
***

## Task
Create a lightweight SQLite-like database management tool capable of handling basic SQL commands, including SELECT, INSERT, UPDATE, and DELETE. The tool operates on CSV files, treating them as database tables, and allows the user to interact with these files through a CLI.

## Description
The My SQLite CLI simulates the behavior of an SQLite database using CSV files as data storage. Users can interact with the data via SQL-like commands, including support for basic table joins, filtering, and data manipulation.

Key Features:

SELECT: Retrieve data from CSV files with optional filtering and column selection.
INSERT: Add new rows to CSV files.
UPDATE: Modify existing rows in CSV files.
DELETE: Remove rows from CSV files.
JOIN: Combine data from two CSV files based on a matching column.

## Installation
1. Clone the repository:
git clone <https://github.com/apelzoid/my-sqlite>
cd my_sqlite

2. Ensure Ruby is installed on your machine:
ruby -v

3. Place your CSV files (e.g., nba_players.csv, nba_player_data.csv) in the same directory as the script.

## Usage
1. my_sqlite_request.rb part
Go to the my_sqlite_request.rb file. At the very bottom uncomment test cases one by one and run the file. Changes can be seen in the nba_player_data.csv file or in the CLI if values are printed out there.

2. my_sqlite_cli.rb part
Run the file:
ruby my_sqlite_cli.rb

Try commands:
1) SELECT Commands
SELECT * FROM nba_player_data
SELECT name,year_start FROM nba_player_data WHERE year_start=2006
SELECT name,birth_date,college FROM nba_player_data WHERE name='Matt Zunic'
SELECT Player, birth_state, birth_city FROM nba_players JOIN nba_player_data ON nba_players.Player=nba_player_data.name WHERE Player='Pascal Siakam'
2) INSERT Commands
INSERT INTO nba_player_data VALUES (4552,"Hugo Boss",1990,2000,"G","6-8",89,"March 8, 1979","RSU")
INSERT INTO nba_players VALUES (3925,3925,Trevor Levor,199,90,Wesrtern Uni,1999,San Antonio,Texas)
3) UPDATE Commands
UPDATE nba_players SET height=1501,weight=109 WHERE ID=1
UPDATE nba_player_data SET name=Hugy Boss WHERE name=Hugo Boss
4) DELETE Commands
DELETE FROM nba_players WHERE ID=3924
DELETE FROM nba_player_data WHERE name=Hugo Boss
5) Type 'quit' to exit.

### The Core Team


<span><i>Made at <a href='https://qwasar.io'>Qwasar SV -- Software Engineering School</a></i></span>
<span><img alt='Qwasar SV -- Software Engineering School's Logo' src='https://storage.googleapis.com/qwasar-public/qwasar-logo_50x50.png' width='20px' /></span>
