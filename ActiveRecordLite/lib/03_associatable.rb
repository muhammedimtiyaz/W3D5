require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    
  end

  def table_name
    self.class.to_s.tableize
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    default = {
      :primary_key => :id,
      :class_name => name.to_s.camelcase
      :foreign_key => "#{name}_id".to_sym
    }

    default.keys.each do |key|
      self.send("#{key}=", options[key]) || default[key]
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    # ...
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    # ...
  end

  def has_many(name, options = {})
    # ...
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
end
