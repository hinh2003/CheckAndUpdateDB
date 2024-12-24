# frozen_string_literal: true

require 'rubyXL'

# this is ExcelController
class ExcelController < ApplicationController

  skip_before_action :verify_authenticity_token

  def index; end

  def read_excel

    cancel_sheet = params[:cancel_sheet].to_i || 0
    excel_importer = ExcelImporter.new(params[:file], cancel_sheet)
    data = excel_importer.read_excel_file

    render json: { tables: data }
  rescue StandardError => e
    render json: { error: "Lỗi khi đọc file Excel: #{e.message}" }, status: :unprocessable_entity
  end


end
