require "csv"
require "readline" # not yet used but is needed as per task description

class MySqliteRequest
  def initialize(table_name = nil)
    @table_name = table_name
    @select_columns = []
    @where_column = nil
    @where_value = nil
    @order_column = nil
    @order_direction = :asc
    @join_table = nil
    @join_column_a = nil
    @join_column_b = nil
    @insert_data = nil
    @update_data = nil
    @delete_flag = false
  end

  def from(table_name)
    @table_name = table_name
    self
  end 

  def select(columns)
    @select_columns = Array(columns) 
    self
  end 
   
  def where(column_name, value)
    @where_column = column_name
    @where_value = value
    self
  end
  
  def join(column_on_db_a, filename_db_b, column_on_db_b)
    @join_table = filename_db_b
    @join_column_a = column_on_db_a
    @join_column_b = column_on_db_b
    self
  end

  def order(order, column_name)
    @order_direction = order
    @order_column = column_name
    self
  end

  def insert(table_name)
    @table_name = table_name
    self
  end

  def values(data)
    @insert_data = data
    self
  end

  def update(table_name)
    @table_name = table_name
    self
  end

  def set(data)
    @update_data = data
    self
  end

  def delete
    @delete_flag = true
    self
  end

  def run
    if @insert_data
      execute_insert
    elsif @update_data
      execute_update
    elsif @delete_flag
      execute_delete
    else
      execute_query
    end
  end

  private

#functions follow:
  def execute_query
    data = load_table(@table_name)
    data = apply_where(data)
    data = apply_join(data) if @join_table
    data = apply_order(data)
    data = select_columns(data)
    data
  end

  def generate_id_for_new_row(rows)
    max_id = rows.map { |row| row["ID"].to_i }.max || 0  
    @insert_data["ID"] = (max_id + 1).to_s  
  end

  def execute_insert
    data = load_table(@table_name)
  
    generate_id_for_new_row(data) #generates new ID
  
    @insert_data = { 'ID' => @insert_data['ID'] }.merge(@insert_data.reject { |key, _| key == 'ID' })    # Ensure the 'ID' is the first key in the new row
  
    data << @insert_data
    save_table(@table_name, data)
    "1 row inserted."
  end

def execute_update
  data = load_table(@table_name)
  data.each do |row|
    if @where_column.nil? || row[@where_column] == @where_value
      @update_data.each { |key, value| row[key] = value }
    end
  end
  save_table(@table_name, data)
  "Update completed."
end

def execute_delete
  data = load_table(@table_name)
  data.reject! { |row| @where_column && row[@where_column] == @where_value }
  save_table(@table_name, data)
  "Delete completed."
end

def load_table(table_name) #loads file and checks if it has ID row
  CSV.read("#{table_name}.csv", headers: true).map(&:to_h).tap do |data| 
    unless data.first&.key?('ID')
      data.each_with_index { |row, index| row['ID'] = (index + 1).to_s }
    end
  end
end

def save_table(table_name, data)
  CSV.open("#{table_name}.csv", 'w') do |csv|
    headers = data.first.keys
    headers.unshift(headers.delete('ID')) if headers.include?('ID') # Moves 'ID' to the front if it exists
    csv << headers

    data.each do |row|
      csv << headers.map { |header| row[header] }
    end
  end
end

def apply_where(data)
  return data unless @where_column
  data.select { |row| row[@where_column] == @where_value }
end

def apply_join(data)
  join_data = load_table(@join_table)
  data.map do |row|
    match = join_data.find { |join_row| join_row[@join_column_b] == row[@join_column_a] }
    row.merge(match || {})
  end
end

def apply_order(data) #by default order is asc but can be set to desc 
  return data unless @order_column

  data.sort_by! { |row| row[@order_column] }
  @order_direction == :desc ? data.reverse : data
end

def select_columns(data)
  return data if @select_columns.empty?
  data.map { |row| row.slice(*@select_columns) }
end
end

#--------------test space (uncomment and run)-------------

# request = MySqliteRequest.new   
# result = request.insert('nba_players')
#        .values({'Player' => 'Janis Berzins Liepins'})
#        .run   
# puts result             

# request = MySqliteRequest.new
# result = request.from('nba_player_data')
#        .select(['name', 'year_end'])
#        .where('name', 'Janis Berzins')
#        .order(:asc, 'name')
#        .run
# puts result 

# request = MySqliteRequest.new
# result = request.update('nba_players')
#        .where('Player', 'Janis Ape666l2s')
#        .set({ 'collage' => 'Latvijas Universitate'})
#        .run
# puts result

# request = MySqliteRequest.new
# request.delete.from('nba_player_data')
#        .where('name', 'Janis Berzins')
#        .run

# request = MySqliteRequest.new
# result = request.from('nba_player_data')
#                 .select(['name', 'birth_state', 'college', 'year_end']) 
#                 .join('name', 'nba_players', 'Player') #column_on_db_a, filename_db_b, column_on_db_b
#                 .run
# puts result