module ChangesHelper
  PER_PAGE = 10

  def add_created_at_attribute
    @items.each do |item|
      date = date_from_filename(item[:filename])
      item[:created_at] = date unless date.nil?
    end
  end

  MimeFormat ||= "application/vnd.github.%s+json".freeze
  # Public: Filters the change items out.  If a version is given, show only the
  # items related to that version.
  #
  # version - Optional String version key.
  #
  # Returns an Array of all 30 Nanoc::Item objects, sorted in reverse
  # chronological order.
  def api_changes(version = nil)
    changes = @items.select { |item| item[:kind] == 'change' }
    if version
      version_s = version.to_s
      changes.select { |item| item[:api_version] == version_s }
    else
      changes
    end.sort! do |x, y|
      attribute_to_time(y[:created_at]) <=> attribute_to_time(x[:created_at])
    end
  end

  def paginated_api_changes(first, last, version = nil)
    changes = api_changes(version)
    changes[first..last]
  end

  def total_pages(version = nil)
    (api_changes(version).length / PER_PAGE).floor + 1
  end

  # Public
  def current_api
    @current_api ||= (api_versions[-2] || api_versions.first).first
  end

  # Public
  def upcoming_api
    @upcoming_api ||= begin
      version, date = api_versions.last
      version unless date
    end
  end

  # Public
  def current_api?(version)
    @api_current_checks ||= {}
    if @api_current_checks.key?(version)
      @api_current_checks[version]
    end

    @api_current_checks[version] = version == current_api
  end

  # Public
  def no_current_api_versions?(*versions)
    versions.none? { |v| current_api?(v) }
  end

  # Public
  def api_released_at(version)
    @api_releases ||= {}
    @api_releases[version] ||= begin
      pair = api_versions.detect do |name, _|
        name == version
      end
      pair[1] if pair
    end
  end

  # Public
  def api_mimetype_listing(version)
    version_s = version.to_s
    mime = mimetype_for version_s
    if time = api_released_at(version_s)
      mime << " ("
      mime << "Current, " if current_api?(version_s)
      mime << strftime(time)
      mime << ")"
    else
      mime
    end
  end

  # Internal
  def mimetype_for(version)
    MimeFormat % version.to_s
  end

  # Internal
  def api_versions
    @api_versions ||= Array(@site.config[:api_versions])
  end
end
