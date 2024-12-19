# frozen_string_literal: true

# this is DatabaseController
class DatabaseController < ApplicationController

  before_action :logged_in_user, only: %i[connect index]

  def index; end

  def connect
    db_params = info_params

    begin
      establish_db_connection(db_params)
      check_db_connection

      tables_info = fetch_tables_and_columns

      render json: { message: 'Kết nối thành công!', tables: tables_info }
    rescue StandardError => e
      render json: { message: "Kết nối thất bại: #{e.message}" }, status: :unprocessable_entity
    end
  end

  private

  def info_params
    params.permit(:host, :username, :password, :database, :adapter)
  end

  def establish_db_connection(db_params)
    ActiveRecord::Base.establish_connection(
      adapter: db_params[:adapter],
      host: db_params[:host],
      username: db_params[:username],
      password: db_params[:password],
      database: db_params[:database]
    )
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
        type: column.sql_type,
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
end
