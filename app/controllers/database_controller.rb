# frozen_string_literal: true

# this is DatabaseController
class DatabaseController < ApplicationController

  before_action :logged_in_user, only: %i[connect index]

  def index; end

  def connect_and_import

    establish_db_connection(info_params)

    cancel_sheet = params[:cancel_sheet].to_i || 0

    excel_importer = ExcelImporter.new(params[:file], cancel_sheet)

    data = excel_importer.read_excel_file

    import_tables_to_db(data)

    render json: { message: 'Dữ liệu đã được import thành công!' }

  rescue StandardError => e
    render json: { error: "Có lỗi xảy ra: #{e.message}" }, status: :unprocessable_entity

  ensure
    ActiveRecord::Base.establish_connection(Rails.application.config.database_configuration[Rails.env])

  end


  def connect
    db_params = info_params

    begin
      establish_db_connection(db_params) do
        tables_info = fetch_tables_and_columns
        render json: { tables: tables_info }
      end
    rescue StandardError => e
      render json: { message: "Kết nối thất bại: #{e.message}" }, status: :unprocessable_entity
    end
  end

  private

  def info_params
    params.permit(:host, :username, :password, :database, :adapter)
  end

  def establish_db_connection(db_params)
    ActiveRecord::Base.connection_pool.with_connection do
      temporary_connection = ActiveRecord::Base.establish_connection(
        adapter: db_params[:adapter],
        host: db_params[:host],
        username: db_params[:username],
        password: db_params[:password],
        database: db_params[:database]
      )
      yield temporary_connection if block_given?
    ensure
      ActiveRecord::Base.establish_connection(Rails.application.config.database_configuration[Rails.env])
    end
  end

  def check_db_connection
    ActiveRecord::Base.connection
  end

  def fetch_tables_and_columns
    ActiveRecord::Base.connection.tables.map do |table_name|
      {
        table: table_name,
        columns: fetch_columns_for_table(table_name)
      }
    end
  end

  def fetch_columns_for_table(table_name)
    ActiveRecord::Base.connection.columns(table_name).map do |column|
      {
        name: column.name,
        data_type: simplify_data_type(column.sql_type),
        default: column.default,
        null: column.null
      }
    end
  end

  def logged_in_user
    return if logged_in?

    flash[:danger] = 'Please log in.'
    redirect_to login_url
  end

  def simplify_data_type(sql_type)
    sql_type.split('(').first
  end

  def import_tables_to_db(tables_info)
    tables_info.each do |table_info|
      create_table_if_not_exists(table_info)
    end
  end

  def create_table_if_not_exists(table_info)
    table_name = table_info[:table]
    columns = table_info[:columns]

    if columns.empty?
      return
    end

    column_definitions = columns.map do |col|
      "#{col[:name]} #{map_data_type(col[:data_type])} #{col[:null] ? 'NULL' : 'NOT NULL'}"
    end.join(', ')

    sql = "CREATE TABLE IF NOT EXISTS #{table_name} (#{column_definitions})"
    ActiveRecord::Base.connection.execute(sql)
  end

  def map_data_type(data_type)
    case data_type
    when 'varchar'
      'VARCHAR(255)'
    when 'int'
      'INT'
    when 'boolean'
      'BOOLEAN'
    else
      'TEXT'
    end
  end
end
