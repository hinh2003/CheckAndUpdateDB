# frozen_string_literal: true

# app/services/link_import.rb
class LinkImport
  def self.convert_google_sheets_link(link)
    if link.include?('docs.google.com/spreadsheets')
      sheet_id = link.match(%r{/d/([^/]+)/})[1]
      gid = link[/gid=(\d+)/, 1] || '0'
      "https://docs.google.com/spreadsheets/d/#{sheet_id}/export?format=xlsx&gid=#{gid}"
    else
      link
    end
  end
end
