module ActiveRecord
  # Declare an enum attribute where the values map to integers in the database, but can be queried by name. Example:
  #
  #   class Conversation < ActiveRecord::Base
  #     enum status: [ :active, :archived ]
  #   end
  #
  #   # conversation.update! status: 0
  #   conversation.active!
  #   conversation.active? # => true
  #   conversation.status  # => "active"
  #
  #   # conversation.update! status: 1
  #   conversation.archived!
  #   conversation.archived? # => true
  #   conversation.status    # => "archived"
  #
  #   # conversation.update! status: 1
  #   conversation.status = "archived"
  #
  # You can set the default value from the database declaration, like:
  #
  #   create_table :conversations do |t|
  #     t.column :status, :integer, default: 0
  #   end
  #
  # Good practice is to let the first declared status be the default.
  #
  # Finally, it's also possible to explicitly map the relation between attribute and database integer:
  #
  #   class Conversation < ActiveRecord::Base
  #     enum status: { active: 0, archived: 1 }
  #   end
  #
  # In rare circumstances you might need to access the mapping directly.
  # The mappings are exposed through a constant with the attributes name:
  #
  #   Conversation::STATUS # => { "active" => 0, "archived" => 1 }
  #
  # Use that constant when you need to know the ordinal value of an enum:
  #
  #   Conversation.where("status <> ?", Conversation::STATUS[:archived])
  module Enum
    def enum(definitions)
      klass = self
      definitions.each do |name, values|
        # DIRECTION = { }
        enum_values = _enum_methods_module.const_set name.to_s.upcase, ActiveSupport::HashWithIndifferentAccess.new
        name        = name.to_sym

        _enum_methods_module.module_eval do
          # def direction=(value) self[:direction] = DIRECTION[value] end
          define_method("#{name}=") { |value|
            unless enum_values.has_key?(value)
              raise ArgumentError, "'#{value}' is not a valid #{name}"
            end
            self[name] = enum_values[value]
          }

          # def direction() DIRECTION.key self[:direction] end
          define_method(name) { enum_values.key self[name] }

          pairs = values.respond_to?(:each_pair) ? values.each_pair : values.each_with_index
          pairs.each do |value, i|
            enum_values[value] = i

            # scope :incoming, -> { where direction: 0 }
            klass.scope value, -> { klass.where name => i }

            # def incoming?() direction == 0 end
            define_method("#{value}?") { self[name] == i }

            # def incoming! update! direction: :incoming end
            define_method("#{value}!") { update! name => value }
          end
        end
      end
    end

    def _enum_methods_module
      @_enum_methods_module ||= begin
        mod = Module.new
        include mod
        mod
      end
    end
  end
end
