# frozen_string_literal: true

# this is ApplicationHelper
module ApplicationHelper
  def full_title(page_title = '')
    base_title = 'Check Database'
    if page_title.empty? # Boolean test
      base_title # Implicit return
    else
      "#{page_title} | #{base_title}" # String concatenation
    end
  end
end
