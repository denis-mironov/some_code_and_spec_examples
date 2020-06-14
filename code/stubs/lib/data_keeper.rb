class DataKeeper

  def self.keep(key, value)
    new.keep(key, value)
  end

  def self.read(key)
    new.read(key)
  end

  def self.read_by_value(value)
    new.read_by_value(value)
  end

  def initialize
    @@data_storage ||= {}
  end

  def keep(key, value)
    @@data_storage[key] = value
  end

  def read(key)
    (@@data_storage || {})[key]
  end

  def read_by_value(value)
    (@@data_storage || {}).key(value)
  end
end
