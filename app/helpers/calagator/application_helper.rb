# Methods added to this helper will be available to all templates in the application.
module Calagator

module ApplicationHelper
  include TimeRangeHelper

  # Returns HTML string of an event or venue description for display in a view.
  def format_description(string)
    sanitize(auto_link(upgrade_br(markdown(string))))
  end

  def markdown(text)
    BlueCloth.new(text, :relaxed => true).to_html
  end

  # Return a HTML string with the BR tags converted to XHTML compliant markup.
  def upgrade_br(content)
    content.gsub('<br>','<br />')
  end

  FLASH_TYPES = [:success, :failure]

  def render_flash
    FLASH_TYPES.map{|type|
      next unless flash[type].present?
      content_tag(:div, :class => "flash #{type} flash_#{type}") do
        "#{type == :failure ? 'ERROR: ' : ''}#{flash[type]}".html_safe
      end
    }.compact.join.html_safe
  end

  def datetime_format(time,format)
    format = format.gsub(/(%[dHImU])/,'*\1')
    time.strftime(format).gsub(/\*0*/,'').html_safe
  end

  def self.source_code_version_raw
    # Return a string describing the source code version being used
    return "" unless system("git status 2>&1 >/dev/null")
    " - Git timestamp: #{`git log -1 --format=format:"%ad" 2>&1`}"
  rescue Errno::ENOENT
    # Fail quietly if that didn't work; we don't want to get in the way.
    ""
  end

  Calagator::ApplicationController::SOURCE_CODE_VERSION = self.source_code_version_raw

  def source_code_version
    Calagator::ApplicationController::SOURCE_CODE_VERSION
  end

  # returns html markup with source (if any), imported/created time, and - if modified - modified time
  def datestamp(item)
    source = if item.source.nil?
      "added directly to #{Calagator.title}"
    else
      "imported from #{link_to truncate(item.source.name, length: 40), url_for(item.source)}"
    end
    created = " <br /><strong>#{normalize_time(item.created_at, format: :html)}</strong>"
    updated = if item.updated_at > item.created_at
      " and last updated <br /><strong>#{normalize_time(item.updated_at, format: :html)}</strong>"
    end
    raw "This item was #{source}#{created}#{updated}."
  end

  # Caches +block+ in view only if the +condition+ is true.
  # http://skionrails.wordpress.com/2008/05/22/conditional-fragment-caching/
  def cache_if(condition, name={}, &block)
    if condition
      cache(name, &block)
    else
      block.call
    end
  end

  # Insert a chunk of +javascript+ into the page, and execute it when the document is ready.
  def insert_javascript(javascript)
    content_for(:javascript_insert) do
      (<<-HERE).html_safe
        <script>
          $(document).ready(function() {
            #{javascript}
          });
        </script>
      HERE
    end
  end

  # Focus cursor on DOM element specified by +xpath_query+ using JavaScript, e.g.:
  #
  #   <% focus_on '#search_field' %>
  def focus_on(xpath_query)
    insert_javascript "$('#{xpath_query}').focus();"
  end

  def subnav_class_for(controller_name, action_name)
    css_class = "#{controller.controller_name}_#{controller.action_name}_subnav"
    css_class += " active" if [controller.controller_name, controller.action_name] == [controller_name, action_name]
    css_class
  end
end

end
