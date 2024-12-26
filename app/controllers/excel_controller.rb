# frozen_string_literal: true

require 'rubyXL'

# this is ExcelController
class ExcelController < ApplicationController

  skip_before_action :verify_authenticity_token
  before_action :logged_in_user, only: %i[connect index]

  def index; end

  def read_excel
    cancel_sheet = fetch_cancel_sheet
    file = fetch_file_from_params
    return if file.nil?

    excel_importer = ExcelImporter.new(file, cancel_sheet)
    data = excel_importer.read_excel_file

    render json: { tables: data }
  rescue StandardError => e
    flash[:error] = e.message
    redirect_to request.referer
  end


  private

  def logged_in_user
    return if logged_in?

    flash[:danger] = 'Please log in.'
    redirect_to login_url
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
    redirect_to request.referer
  end

end
