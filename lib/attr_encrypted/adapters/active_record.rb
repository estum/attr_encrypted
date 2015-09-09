require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/module/aliasing'

module AttrEncrypted
  module ActiveRecord
    extend ActiveSupport::Concern

    included do
      alias_method_chain :reload, :attr_encrypted
      alias_method_chain :assign_attributes, :attr_encrypted
      alias_method :attributes=, :assign_attributes_with_attr_encrypted
      attr_encrypted_options[:encode] = true
    end

    module ClassMethods
      protected

      # <tt>attr_encrypted</tt> method
      def attr_encrypted(*)
        super do |attribute_name|
          alias_method :"#{attribute_name}_before_type_cast", attribute_name
        end
      end

      def attribute_method_already_implemented?(method_name)
        super || attribute_method?(method_name)
      end
    end

    # https://github.com/attr-encrypted/attr_encrypted/issues/68
    def reload_with_attr_encrypted(*args, &block)
      reload_without_attr_encrypted(*args, &block).tap do
        self.class.encrypted_attributes.each_key do |attribute_name|
          instance_variable_set(:"@#{attribute_name}", nil)
        end
      end
    end

    def assign_attributes_with_attr_encrypted(new_attributes)
      return if new_attributes.blank?
      new_attributes = new_attributes.to_options
      encrypted_part = new_attributes.extract!(*self.class.encrypted_attributes.keys)

      assign_attributes_without_attr_encrypted(new_attributes)
      assign_attributes_without_attr_encrypted(encrypted_part)
    end
  end
end
