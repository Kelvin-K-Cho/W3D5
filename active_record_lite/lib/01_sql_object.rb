require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    # ...
    return @columns if @columns
    cols = DBConnection.execute2(<<-SQL).first
    SELECT
      *
    FROM
      #{self.table_name}
    SQL
    cols.map!{ |name| name.to_sym }
    @columns = cols
  end

  def self.finalize!
    self.columns.each do |col|
      define_method(col) { self.attributes[col] }
      define_method("#{col}=") { |value| self.attributes[col] = value }
    end
  end

  def self.table_name=(table_name)
    # ...
    @table_name = table_name
  end

  def self.table_name
    # ...
    @table_name || self.name.underscore.pluralize
  end

  def self.all
    # ...
    everything = DBConnection.execute(<<-SQL)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
    SQL
    parse_all(everything)
  end

  def self.parse_all(results)
    # ...
    results.map{|result| self.new(result)}
  end

  def self.find(id)
    # ...
    everything = DBConnection.execute(<<-SQL, id)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
      WHERE
        #{self.table_name}.id = ?
    SQL
    parse_all(everything).first
  end

  def initialize(params = {})
    # ...
    params.each do |attribute, value|
      attribute = attribute.to_sym
      if self.class.columns.include?(attribute)
        self.send("#{attribute}=", value)
      else
        raise "unknown attribute '#{attribute}'"
      end
    end
  end

  def attributes
    # ...
    @attributes ||= {}
  end

  def attribute_values
    # ...
    self.class.columns.map { |attribute| self.send(attribute) }
  end

  def insert
    # ...
    cols = self.class.columns.drop(1)
    col_names = cols.map{ |name| name.to_s }.join(', ')
    question_marks = (["?"] * cols.count).join(', ')
    DBConnection.execute(<<-SQL, attribute_values.drop(1))
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    # ...
    set_line = self.class.columns.map do |attribute|
      "#{attribute} = ?"
    end.join(', ')
    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        #{self.class.table_name}.id = ?
    SQL
  end

  def save
    # ...
    if id == nil
      self.insert
    else
      self.update
    end
  end
end
