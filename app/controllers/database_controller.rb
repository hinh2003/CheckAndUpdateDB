# frozen_string_literal: true

# this is DatabaseController
class DatabaseController < ApplicationController

  before_action :logged_in_user, only: %i[connect index]

  def index; end

  def connect_and_import
    establish_db_connection(info_params) do
      cancel_sheet = params[:cancel_sheet].to_i || 0
      if params[:link].present?
        link = LinkImport.convert_google_sheets_link(params[:link])
        file = download_file_from_url(link)
      elsif params[:file].present?
        file = params[:file]
      else
        flash[:error] = 'Không tìm thấy file hoặc URL để import.'
        redirect_to request.referer and return
      end
      excel_importer = ExcelImporter.new(file, cancel_sheet)
      data = excel_importer.read_excel_file
      import_tables_to_db(data)

      flash[:success] = 'Thêm thành công'
      redirect_to request.referer
    end
  rescue StandardError => e
    Rails.logger.error("Database connection error: #{e.message}")
    flash[:info] = "Có lỗi xảy ra: #{e.message}"
    redirect_to request.referer
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

  def download_file_from_url(url)
    require 'open-uri'
    begin
      URI.open(url)
    rescue StandardError => e
      Rails.logger.error("Lỗi tải file từ URL: #{e.message}")
      flash[:error] = "Không thể tải file từ URL: #{e.message}"
      redirect_to request.referer and return
    end
  end

  def establish_db_connection(db_params)
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
        data_type: column.sql_type,
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
    table_name = table_info[:table].gsub(/\s+/, '')
    columns = table_info[:columns]

    return if columns.empty?

    column_definitions = columns.map do |col|
      column_name = "`#{col[:name].gsub(/\s+/, '')}`"

      column_def = "#{column_name} #{map_data_type(col[:data_type])}"

      if col[:default] && col[:default] == 'NULL' && col[:null]
        column_def += ' DEFAULT NULL'
      elsif col[:default] && col[:default] != 'NULL' && !%w[text decimal json].include?(col[:data_type])
        column_def += " DEFAULT #{format_default_value(col[:default])}"
      end

      column_def += " #{col[:null] ? 'NULL' : 'NOT NULL'}"
      column_def
    end.join(', ')

    sql = "CREATE TABLE IF NOT EXISTS #{table_name} (#{column_definitions})"
    ActiveRecord::Base.connection.execute(sql)
  end

  def map_data_type(data_type)
    case data_type
    when /varchar\(\d+\)/
      data_type
    when 'bigint'
      'BIGINT'
    when 'smallint'
      'SMALLINT'
    when 'int'
      'INT'
    when 'boolean'
      'BOOLEAN'
    when 'text'
      'TEXT'
    when 'datetime'
      'DATETIME'
    when /decimal\(\d+,\d+\)/
      data_type
    when 'tinyint(1)'
      'TINYINT(1)'
    when 'json'
      'JSON'
    when 'float'
      'FLOAT'
    when 'date'
      'DATE'
    else
      'TEXT'
    end
  end

  def format_default_value(default_value)
    if default_value.nil?
      'NULL'
    elsif default_value.is_a?(String)
      "'#{default_value}'"
    else
      default_value.to_s
    end
  end
end
