class GELFLogger < GELF::Logger
  alias original_add add

  def add(level, message = nil, progname = nil)
    if message.nil?
      if block_given?
        message = yield
      else
        message = progname
        progname = default_options['facility']
      end
    end

    original_add(level, formatter.call(level, nil, progname, message), progname)
  end
end
