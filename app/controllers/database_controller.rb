# frozen_string_literal: true

# this is DatabaseController
class DatabaseController < ApplicationController
  include DatabaseHelper
  skip_before_action :verify_authenticity_token

  before_action :logged_in_user, only: %i[connect index]

  def index; end

  def connect_and_import
    establish_connection_and_process do
      file = fetch_file_from_params
      return if file.nil?

      import_excel_file(file)
      flash[:success] = 'Thêm thành công'
      redirect_to request.referer
    end
  rescue StandardError => e
    handle_import_error(e)
  end

  def connect
    db_params = info_params
    begin
      DatabaseHelper.establish_db_connection(db_params) do
        tables_info = DatabaseHelper.fetch_tables_and_columns
        render json: { tables: tables_info }
      end
    rescue StandardError => e
      flash[:danger] = e.message
      redirect_to request.referer
    end
  end

  private

  def info_params
    params.permit(:host, :username, :password, :database, :adapter)
  end

  def logged_in_user
    return if logged_in?

    flash[:danger] = 'Please log in.'
    redirect_to login_path
  end

  def import_tables_to_db(tables_info)
    adapter = params[:adapter]

    tables_info.each do |table_info|
      DatabaseHelper.create_table_if_not_exists(table_info , adapter)
    end
  end

  def establish_connection_and_process
    DatabaseHelper.establish_db_connection(info_params) do
      cancel_sheet = fetch_cancel_sheet
      yield(cancel_sheet) # Yield to process the file inside the block
    end
  end

  def import_excel_file(file)
    cancel_sheet = fetch_cancel_sheet
    excel_importer = ExcelImporter.new(file, cancel_sheet)
    data = excel_importer.read_excel_file
    import_tables_to_db(data)
  end

  def handle_import_error(error)
    Rails.logger.error("Database connection error: #{error.message}")
    flash[:info] = "Có lỗi xảy ra: #{error.message}"
    redirect_to request.referer
  end

  def fetch_cancel_sheet
    params[:cancel_sheet].to_i || 0
  end

  def fetch_file_from_params
    if params[:link].present?
      fetch_file_from_link
    elsif params[:file].present?
      params[:file]
    else
      handle_missing_file
    end
  end

  def fetch_file_from_link
    link = LinkImport.convert_google_sheets_link(params[:link])
    DatabaseHelper.download_file_from_url(link)
  end

  def handle_missing_file
    flash[:error] = 'Không tìm thấy file hoặc URL để import.'
    redirect_to request.referer and return nil
  end

end
