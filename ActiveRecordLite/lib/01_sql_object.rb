require 'byebug'
require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns
    cols = DBConnection.instance.execute2(<<-SQL).first
      SELECT
        *
      FROM
        #{self.table_name}
      SQL
    cols.map!(&:to_sym)
    @columns = cols
  end

  def self.finalize!
    columns.each do |col_name|
      define_method("#{col_name}") do
        self.attributes[col_name]
      end

      define_method("#{col_name}=") do |value|
        self.attributes[col_name] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.to_s.tableize
  end

  def self.all
    instances = DBConnection.execute(<<-SQL)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
    SQL

    self.parse_all(instances)
  end

  def self.parse_all(results)

    results.map { |hash| self.new(hash) }
  end

  def self.find(id)
    self.all.find { |obj| obj.id == id }
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      if self.class.columns.include?(attr_name.to_sym)
        self.send("#{attr_name.to_sym}=", value)
      else
        raise "unknown attribute '#{attr_name}'"
      end
    end
  end

  def attributes
    @attributes ||= {}

  end

  def attribute_values
    self.class.columns.map { |col| send(col) }
  end

  def insert
    cols = self.class.columns.drop(1)
    col_names = cols.map(&:to_s).join(", ")
    question_marks = (["?"] * cols.length).join(", ")
    DBConnection.execute(<<-SQL, *self.attribute_values.drop(1))
    INSERT INTO
      #{self.class.table_name}(#{col_names})
    VALUES
      (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_values = self.class.columns.map { |attribute| "#{attribute} = ?" }.join(", ")
    DBConnection.execute(<<-SQL, *self.attribute_values, id)
    UPDATE
      #{self.class.table_name}
    SET
      #{set_values}
    WHERE
      #{self.class.table_name}.id = ?
    SQL
  end

  def save
    if self.id.nil?
      self.insert
    else
      self.update
    end
  end

end
