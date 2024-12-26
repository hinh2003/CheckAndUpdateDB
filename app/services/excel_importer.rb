# app/services/excel_importer.rb
class ExcelImporter
  def initialize(file, cancel_sheet)
    @file = file
    @cancel_sheet = cancel_sheet.to_i

  end

  def read_excel_file
    workbook = RubyXL::Parser.parse(@file)
    data = []

    workbook.worksheets.each_with_index do |sheet, index|
      next if index < @cancel_sheet

      data << process_sheet(sheet)
    end

    data
  end

  private

  def process_sheet(sheet)
    table_name = sheet.sheet_name
    sheet_data = { table: table_name, columns: [] }

    sheet.each_with_index do |row, index|
      next if index < 4

      column_name = row[2]&.value
      break if column_name.nil? || column_name.strip.empty?

      column_info = {
        name: column_name,
        data_type: row[3]&.value,
        default: row[5]&.value,
        null: row[4]&.value == 'Yes'
      }
      sheet_data[:columns] << column_info
    end
    sheet_data
  end
end
