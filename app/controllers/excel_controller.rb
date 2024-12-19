# frozen_string_literal: true

require 'rubyXL'

# this is ExcelController
class ExcelController < ApplicationController
  def index; end

  def read_excel

    data = read_excel_file(params[:file])

    render json: { tables: data }
  rescue StandardError => e
    render json: { error: "Lỗi khi đọc file Excel: #{e.message}" }, status: :unprocessable_entity

  end

  private

  def read_excel_file(file)
    workbook = RubyXL::Parser.parse(file)
    data = []

    workbook.worksheets.each_with_index do |sheet, index|

      next if index <  cancel_params['cancel_sheet'].to_i


      data << process_sheet(sheet)
    end

    data
  end

  def process_sheet(sheet)
    table_name = sheet.sheet_name
    sheet_data = { table_name: table_name, columns: [] }

    sheet.each_with_index do |row, index|
      next if index < 4

      column_name = row[2]&.value
      break if column_name.nil? || column_name.strip.empty?

      column_info = {
        column_name: column_name,
        data_type: row[3]&.value,
        not_null: row[4]&.value == 'Yes',
        default_value: row[5]&.value
      }
      sheet_data[:columns] << column_info
    end
    sheet_data
  end

  def cancel_params
    params.permit(:cancel_sheet)
  end

end
