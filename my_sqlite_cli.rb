require "readline"
require_relative "my_sqlite_request"

class MySqliteQueryCli
  def initialize
    puts "Welcome to MySQLite Query"
    puts "Type your query or type 'quit' to exit"
  end

  # Main parser to determine the type of SQL command and delegate to specific handlers
  def parse(buf)
    buf.strip! # Remove any extra whitespace from the input

    # Match the command type and call the corresponding handler
    if buf.match?(/^SELECT/i)
      handle_select(buf)
    elsif buf.match?(/^INSERT/i)
      handle_insert(buf)
    elsif buf.match?(/^UPDATE/i)
      handle_update(buf)
    elsif buf.match?(/^DELETE/i)
      handle_delete(buf)
    else
      # If the command doesn't match, display an error
      puts "Unknown command: #{buf.split.first}"
    end
  end

  # Main loop for running the CLI
  def run!
    while buf = Readline.readline("> ", true)
      break if buf.strip.downcase == "quit" # Exit when user types "quit"
      begin
        parse(buf) # Parse the input query
      rescue StandardError => e
        # Catch and display any runtime errors
        puts "Error: #{e.message}" 
      end
    end
  end

  private

  # SELECT Handler
  # Processes SELECT queries, including JOINs and WHERE clauses
  def handle_select(buf)
    # Check if the query involves a JOIN
    join_match = buf.match(/^SELECT\s+(.+?)\s+FROM\s+(\S+)\s+JOIN\s+(\S+)\s+ON\s+(\S+)\s*=\s*(\S+)(?:\s+WHERE\s+(.+))?/i)
    
    if join_match
      # Parse JOIN query components
      columns = join_match[1].strip == "*" ? [] : join_match[1].split(",").map(&:strip)
      table1 = join_match[2].strip
      table2 = join_match[3].strip
      join_column1 = join_match[4].strip
      join_column2 = join_match[5].strip
      where_clause = join_match[6]&.strip
      
      # Build the request with JOIN and WHERE conditions
      request = MySqliteRequest.new
        .from(table1)
        .select(columns)
        .join(join_column1, table2, join_column2)
      
      # Add WHERE condition if present
      if where_clause
        column, value = where_clause.split(/\s*=\s*/).map(&:strip)
        value = value.gsub(/^['"]|['"]$/, '') # Remove quotes from the value
        request.where(column, value)
      end
      
      # Execute the query and display results
      results = request.run
      display_results(results)
    else
      # Process a basic SELECT query
      match = buf.match(/^SELECT\s+(.+?)\s+FROM\s+(\S+)(?:\s+WHERE\s+(.+))?/i)
      raise "Invalid SELECT syntax" unless match
      
      # Extract columns, table name, and WHERE condition
      columns = match[1].strip == "*" ? [] : match[1].split(",").map(&:strip)
      table_name = match[2].strip
      where_clause = match[3]&.strip
      
      # Build the request
      request = MySqliteRequest.new.from(table_name).select(columns)
      if where_clause
        column, value = where_clause.split(/\s*=\s*/).map(&:strip)
        value = value.gsub(/^['"]|['"]$/, '')
        request.where(column, value)
      end
      
      # Execute the query and display results
      results = request.run
      display_results(results)
    end
  end

  # INSERT Handler
  # Processes INSERT queries
  def handle_insert(buf)
    # Match the INSERT syntax
    match = buf.match(/^INSERT\s+INTO\s+(\S+)\s+VALUES\s+\((.+)\)/i)
    raise "Invalid INSERT syntax" unless match
  
    table_name = match[1].strip # Extract table name
    values = parse_values(match[2]) # Parse the provided values
    headers = load_table_headers(table_name) # Load headers from the table

    # Ensure the number of values matches the headers  
    raise "Mismatch between columns and values" if headers.size != values.size
  
    # Build the data hash and execute the insert
    data = headers.zip(values).to_h
    request = MySqliteRequest.new.insert(table_name).values(data)
    puts request.run
  end

  # UPDATE Handler
  # Processes UPDATE queries
    def handle_update(buf)
      # Match the UPDATE syntax
      match = buf.match(/^UPDATE\s+(\S+)\s+SET\s+(.+?)(?:\s+WHERE\s+(.+))?$/i)
      raise "Invalid UPDATE syntax" unless match
  
      table_name = match[1].strip # Extract table name
      set_clause = match[2].strip # Extract SET clause
      where_clause = match[3]&.strip # Extract WHERE clause 
  
      update_data = parse_update_set(set_clause) # Parse the SET clause

      # Build the request
      request = MySqliteRequest.new.update(table_name).set(update_data)
      
      # Add WHERE condition if present
      if where_clause
        column, value = where_clause.split("=").map(&:strip)
        value = value.tr("'", "") if value
        request.where(column, value)
      end
      # Execute the update and display result
      puts request.run
    end

  # DELETE Handler
  # Processes DELETE queries
  def handle_delete(buf)
    # Match the DELETE syntax
    match = buf.match(/^DELETE\s+FROM\s+(\S+)(?:\s+WHERE\s+(.+))?/i)
    raise "Invalid DELETE syntax" unless match

    table_name = match[1].strip # Extract table name
    where_clause = match[2]&.strip # Extract WHERE clause

    # Build the delete request
    request = MySqliteRequest.new.from(table_name).delete
    if where_clause
      column, value = where_clause.split("=").map(&:strip)
      value = value.tr("'", "") if value
      request.where(column, value)
    end
    # Execute the delete and display result
    puts request.run
  end

  ### Helper Methods

  # Parse values for INSERT queries
  def parse_values(values_str)
  # Match quoted and unquoted values
    values_str.scan(/"[^"]*"|'[^']*'|[^,()]+/).map { |v| v.gsub(/^["']|["']$/, '').strip }
  end

  # Parse the SET clause for UPDATE queries
  def parse_update_set(set_clause)
    # Match key-value pairs and remove quotes from values
    updates = set_clause.scan(/(\w+)\s*=\s*('[^']*'|"[^"]*"|[^,]+)/).map do |key, value|
      [key.strip, value.gsub(/^["']|["']$/, '').strip] # Remove surrounding quotes
    end

    updates.to_h
  rescue StandardError => e
    raise "Invalid SET syntax. Format: SET column1=value1, column2=value2"
  end

  # Load table headers from the CSV file
  def load_table_headers(table_name)
    CSV.read("#{table_name}.csv", headers: true).headers.tap do |headers|
      raise "Table does not exist or has no headers" if headers.nil? || headers.empty?
    end
  end

  # Display query results in a formatted way
  def display_results(results)
    if results.empty?
      puts "No results found."
    else
      headers = results.first.keys
      puts headers.join("\t")
      results.each { |row| puts row.values.join("\t") }
    end
  end
end

# Run the CLI
MySqliteQueryCli.new.run!

#SELECT * FROM nba_player_data
#SELECT name,birth_date,college FROM nba_player_data WHERE name='Hugy Boss'
#SELECT name,height,birth_city FROM nba_player_data WHERE =201
#SELECT Player, birth_state, birth_city FROM nba_players JOIN nba_player_data ON nba_players.Player=nba_player_data.name WHERE Player='Pascal Siakam'
#INSERT INTO nba_player_data VALUES (4553,"Hugo Boss",1990,2000,"G","6-8",89,"March 8, 1979","RSU")
#INSERT INTO nba_players VALUES (3925,3925,Trevor Levor,199,90,Wesrtern Uni,1999,San Antonio,Texas)
#UPDATE nba_players SET height=1501,weight=109 WHERE ID=1
#UPDATE nba_player_data SET name=Hugy Boss WHERE name=Hugo Boss
#DELETE FROM nba_players WHERE ID=3924
#DELETE FROM nba_player_data WHERE name=Hugy Boss