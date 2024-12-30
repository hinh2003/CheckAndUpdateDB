# frozen_string_literal: true

# this is DatabaseHelper
module DatabaseHelper

  def self.establish_db_connection(db_params)
    ActiveRecord::Base.establish_connection(
      adapter: db_params[:adapter],
      host: db_params[:host],
      username: db_params[:username],
      password: db_params[:password],
      database: db_params[:database]
    )
    ActiveRecord::Base.connection.active? || raise(ActiveRecord::ConnectionNotEstablished)
    yield if block_given?
  ensure
    ActiveRecord::Base.establish_connection(Rails.application.config.database_configuration[Rails.env])
  end

  def self.fetch_tables_and_columns
    ActiveRecord::Base.connection.tables.map do |table_name|
      {
        table: table_name,
        columns: fetch_columns_for_table(table_name)
      }
    end
  end

  def self.fetch_columns_for_table(table_name)
    ActiveRecord::Base.connection.columns(table_name).map do |column|
      {
        name: column.name,
        data_type: column.sql_type,
        default: column.default,
        null: column.null
      }
    end
  end

  def self.create_table_if_not_exists(table_info, adapter)
    table_name = table_info[:table].gsub(/\s+/, '')
    columns = table_info[:columns]

    return if columns.empty?

    column_definitions = columns.map do |col|
      column_name = adapter == 'postgresql' ? "\"#{col[:name].gsub(/\s+/, '')}\"" : "`#{col[:name].gsub(/\s+/, '')}`"

      column_def = "#{column_name} #{map_data_type(col[:data_type], adapter)}"

      if col[:default] && col[:default] == 'NULL' && col[:null]
        column_def += ' DEFAULT NULL'
      elsif col[:default] && col[:default] != 'NULL' && !%w[text decimal json].include?(col[:data_type])
        column_def += " DEFAULT #{format_default_value(col[:default])}"
      end
      column_def += " #{col[:null] ? 'NULL' : 'NOT NULL'}"
      column_def
    end.join(', ')

    sql = case adapter
          when 'postgresql'
            "CREATE TABLE IF NOT EXISTS #{table_name} (#{column_definitions})"
          when 'mysql2'
            "CREATE TABLE IF NOT EXISTS #{table_name} (#{column_definitions})"
          else
            raise "Unsupported adapter: #{adapter}"
          end

    ActiveRecord::Base.connection.execute(sql)
  end

  def self.map_data_type(data_type, adapter)
    type_map = get_type_map(adapter)

    raise "Unsupported adapter: #{adapter}" unless type_map

    if type_map.key?(data_type)
      value = type_map[data_type]
      value.is_a?(Proc) ? value.call(data_type) : value
    else
      'TEXT'
    end
  end

  def self.get_type_map(adapter)
    case adapter
    when 'postgresql'
      {
        /varchar\(\d+\)/ => ->(dt) { dt },
        'bigint' => 'BIGINT',
        'smallint' => 'SMALLINT',
        'int' => 'INTEGER',
        'boolean' => 'BOOLEAN',
        'text' => 'TEXT',
        'datetime' => 'TIMESTAMP',
        /decimal\(\d+,\d+\)/ => ->(dt) { dt },
        'tinyint(1)' => 'SMALLINT',
        'json' => 'JSONB',
        'float' => 'FLOAT',
        'date' => 'DATE'
      }
    when 'mysql2'
      {
        /varchar\(\d+\)/ => ->(dt) { dt },
        'bigint' => 'BIGINT',
        'smallint' => 'SMALLINT',
        'int' => 'INT',
        'boolean' => 'BOOLEAN',
        'text' => 'TEXT',
        'datetime' => 'DATETIME',
        /decimal\(\d+,\d+\)/ => ->(dt) { dt },
        'tinyint(1)' => 'TINYINT(1)',
        'json' => 'JSON',
        'float' => 'FLOAT',
        'date' => 'DATE'
      }
    else
      #
    end
  end

  def self.format_default_value(default_value)
    if default_value.nil?
      'NULL'
    elsif default_value.is_a?(String)
      "'#{default_value}'"
    else
      default_value.to_s
    end
  end

  def self.download_file_from_url(url)
    require 'open-uri'
    begin
      URI.open(url)
    rescue StandardError => e
      Rails.logger.error("Lỗi tải file từ URL: #{e.message}")
      flash[:error] = "Không thể tải file từ URL: #{e.message}"
      redirect_to request.referer and return
    end
  end

end
