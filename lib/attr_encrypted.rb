require 'attr_encrypted/version'
require 'encryptor'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/array/extract_options'
require 'active_support/core_ext/hash/reverse_merge'
require 'active_support/dependencies/autoload'
require 'active_support/concern'

# Adds attr_accessors that encrypt and decrypt an object's attributes
module AttrEncrypted
  extend ActiveSupport::Concern
  extend ActiveSupport::Autoload

  autoload_under "adapters" do
    autoload :ActiveRecord
  end

  ##
  # :singleton-method: attr_encrypted_options
  # Default options to use with calls to <tt>attr_encrypted</tt>
  #
  # It will inherit existing options from its superclass

  ##
  # :singleton-method: encrypted_attributes
  # Contains a hash of encrypted attributes with virtual attribute names as keys
  # and their corresponding options as values
  #
  # Example
  #
  #   class User
  #     attr_encrypted :email, :key => 'my secret key'
  #   end
  #
  #   User.encrypted_attributes # { :email => { :attribute => 'encrypted_email', :key => 'my secret key' } }


  included do
    class_attribute :attr_encrypted_options, instance_accessor: false
    self.attr_encrypted_options ||= {}

    class_attribute :encrypted_attributes, instance_accessor: false
    self.encrypted_attributes ||= {}

    if defined?(::ActiveRecord) && self <= ::ActiveRecord::Base
      include AttrEncrypted::ActiveRecord
    end
  end

  module ClassMethods
    DEFAULT_ATTR_ENCRYPTED_OPTIONS = {
      :prefix           => 'encrypted_',
      :suffix           => '',
      :if               => true,
      :unless           => false,
      :encode           => false,
      :default_encoding => 'm',
      :marshal          => false,
      :marshaler        => Marshal,
      :dump_method      => 'dump',
      :load_method      => 'load',
      :encryptor        => Encryptor,
      :encrypt_method   => 'encrypt',
      :decrypt_method   => 'decrypt',
      :mode             => :single_iv_and_salt
    }

    private_constant :DEFAULT_ATTR_ENCRYPTED_OPTIONS

    # Generates attr_accessors that encrypt and decrypt attributes transparently
    #
    # Options (any other options you specify are passed to the encryptor's encrypt and decrypt methods)
    #
    #   :attribute        => The name of the referenced encrypted attribute. For example
    #                        <tt>attr_accessor :email, :attribute => :ee</tt> would generate an
    #                        attribute named 'ee' to store the encrypted email. This is useful when defining
    #                        one attribute to encrypt at a time or when the :prefix and :suffix options
    #                        aren't enough. Defaults to nil.
    #
    #   :prefix           => A prefix used to generate the name of the referenced encrypted attributes.
    #                        For example <tt>attr_accessor :email, :password, :prefix => 'crypted_'</tt> would
    #                        generate attributes named 'crypted_email' and 'crypted_password' to store the
    #                        encrypted email and password. Defaults to 'encrypted_'.
    #
    #   :suffix           => A suffix used to generate the name of the referenced encrypted attributes.
    #                        For example <tt>attr_accessor :email, :password, :prefix => '', :suffix => '_encrypted'</tt>
    #                        would generate attributes named 'email_encrypted' and 'password_encrypted' to store the
    #                        encrypted email. Defaults to ''.
    #
    #   :key              => The encryption key. This option may not be required if you're using a custom encryptor. If you pass
    #                        a symbol representing an instance method then the :key option will be replaced with the result of the
    #                        method before being passed to the encryptor. Objects that respond to :call are evaluated as well (including procs).
    #                        Any other key types will be passed directly to the encryptor.
    #
    #   :encode           => If set to true, attributes will be encoded as well as encrypted. This is useful if you're
    #                        planning on storing the encrypted attributes in a database. The default encoding is 'm' (base64),
    #                        however this can be overwritten by setting the :encode option to some other encoding string instead of
    #                        just 'true'. See http://www.ruby-doc.org/core/classes/Array.html#M002245 for more encoding directives.
    #                        Defaults to false unless you're using it with ActiveRecord, DataMapper, or Sequel.
    #
    #   :default_encoding => Defaults to 'm' (base64).
    #
    #   :marshal          => If set to true, attributes will be marshaled as well as encrypted. This is useful if you're planning
    #                        on encrypting something other than a string. Defaults to false unless you're using it with ActiveRecord
    #                        or DataMapper.
    #
    #   :marshaler        => The object to use for marshaling. Defaults to Marshal.
    #
    #   :dump_method      => The dump method name to call on the <tt>:marshaler</tt> object to. Defaults to 'dump'.
    #
    #   :load_method      => The load method name to call on the <tt>:marshaler</tt> object. Defaults to 'load'.
    #
    #   :encryptor        => The object to use for encrypting. Defaults to Encryptor.
    #
    #   :encrypt_method   => The encrypt method name to call on the <tt>:encryptor</tt> object. Defaults to 'encrypt'.
    #
    #   :decrypt_method   => The decrypt method name to call on the <tt>:encryptor</tt> object. Defaults to 'decrypt'.
    #
    #   :if               => Attributes are only encrypted if this option evaluates to true. If you pass a symbol representing an instance
    #                        method then the result of the method will be evaluated. Any objects that respond to <tt>:call</tt> are evaluated as well.
    #                        Defaults to true.
    #
    #   :unless           => Attributes are only encrypted if this option evaluates to false. If you pass a symbol representing an instance
    #                        method then the result of the method will be evaluated. Any objects that respond to <tt>:call</tt> are evaluated as well.
    #                        Defaults to false.
    #
    #   :mode             => Selects encryption mode for attribute: choose <tt>:single_iv_and_salt</tt> for compatibility
    #                        with the old attr_encrypted API: the default IV and salt of the underlying encryptor object
    #                        is used; <tt>:per_attribute_iv_and_salt</tt> uses a per-attribute IV and salt attribute and
    #                        is the recommended mode for new deployments.
    #                        Defaults to <tt>:single_iv_and_salt</tt>.
    #
    # You can specify your own default options
    #
    #   class User
    #     # now all attributes will be encoded and marshaled by default
    #     attr_encrypted_options.merge!(:encode => true, :marshal => true, :some_other_option => true)
    #     attr_encrypted :configuration, :key => 'my secret key'
    #   end
    #
    #
    # Example
    #
    #   class User
    #     attr_encrypted :email, :credit_card, :key => 'some secret key'
    #     attr_encrypted :configuration, :key => 'some other secret key', :marshal => true
    #   end
    #
    #   @user = User.new
    #   @user.encrypted_email # nil
    #   @user.email? # false
    #   @user.email = 'test@example.com'
    #   @user.email? # true
    #   @user.encrypted_email # returns the encrypted version of 'test@example.com'
    #
    #   @user.configuration = { :time_zone => 'UTC' }
    #   @user.encrypted_configuration # returns the encrypted version of configuration
    #
    #   See README for more examples
    def attr_encrypted(*attributes)
      options = DEFAULT_ATTR_ENCRYPTED_OPTIONS.merge(attr_encrypted_options).merge!(attributes.extract_options!)

      options[:encode] = options[:default_encoding] if options[:encode].is_a?(TrueClass)

      attributes.each do |attribute|
        encrypted_attribute_name = (options[:attribute] ? options[:attribute] : [options[:prefix], attribute, options[:suffix]].join.to_sym)
        iv_name = :"#{encrypted_attribute_name}_iv"
        salt_name = :"#{encrypted_attribute_name}_salt"
        ivar_name = :"@#{attribute}"

        attr_reader encrypted_attribute_name unless attribute_method_already_implemented?(encrypted_attribute_name)
        attr_writer encrypted_attribute_name unless attribute_method_already_implemented?(:"#{encrypted_attribute_name}=")

        if options[:mode] == :per_attribute_iv_and_salt
          attr_reader iv_name unless attribute_method_already_implemented?(iv_name)
          attr_writer iv_name unless attribute_method_already_implemented?(:"#{iv_name}=")

          attr_reader salt_name unless attribute_method_already_implemented?(salt_name)
          attr_writer salt_name unless attribute_method_already_implemented?(:"#{salt_name}=")
        end

        define_method(attribute) do
          instance_variable_get(ivar_name) || instance_variable_set(ivar_name, decrypt(attribute, send(encrypted_attribute_name)))
        end

        define_method(:"#{attribute}=") do |value|
          send(:"#{encrypted_attribute_name}=", encrypt(attribute, value))
          instance_variable_set(ivar_name, value)
        end

        define_method(:"#{attribute}?") do
          send(attribute).present?
        end

        encrypted_attributes[attribute.to_sym] = options.merge(:attribute => encrypted_attribute_name)

        yield(attribute) if block_given?
      end
    end

    alias_method :attr_encryptor, :attr_encrypted

    protected :attr_encryptor, :attr_encrypted

    # Checks if an attribute is configured with <tt>attr_encrypted</tt>
    #
    # Example
    #
    #   class User
    #     attr_accessor :name
    #     attr_encrypted :email
    #   end
    #
    #   User.attr_encrypted?(:name)  # false
    #   User.attr_encrypted?(:email) # true
    def attr_encrypted?(attribute)
      encrypted_attributes.include?(attribute.to_sym)
    end

    # Decrypts a value for the attribute specified
    #
    # Example
    #
    #   class User
    #     attr_encrypted :email
    #   end
    #
    #   email = User.decrypt(:email, 'SOME_ENCRYPTED_EMAIL_STRING')
    def decrypt(attribute, encrypted_value, options = {})
      options = encrypted_attributes[attribute.to_sym].merge(options)
      if options[:if] && !options[:unless] && !encrypted_value.nil? && !(encrypted_value.is_a?(String) && encrypted_value.empty?)
        encrypted_value = encrypted_value.unpack(options[:encode]).first if options[:encode]
        value = options[:encryptor].send(options[:decrypt_method], options.merge!(:value => encrypted_value))
        if options[:marshal]
          value = options[:marshaler].send(options[:load_method], value)
        elsif defined?(Encoding)
          encoding = Encoding.default_internal || Encoding.default_external
          value = value.force_encoding(encoding.name)
        end
        value
      else
        encrypted_value
      end
    end

    # Encrypts a value for the attribute specified
    #
    # Example
    #
    #   class User
    #     attr_encrypted :email
    #   end
    #
    #   encrypted_email = User.encrypt(:email, 'test@example.com')
    def encrypt(attribute, value, options = {})
      options = encrypted_attributes[attribute.to_sym].merge(options)
      if options[:if] && !options[:unless] && !value.nil? && !(value.is_a?(String) && value.empty?)
        value = options[:marshal] ? options[:marshaler].send(options[:dump_method], value) : value.to_s
        encrypted_value = options[:encryptor].send(options[:encrypt_method], options.merge!(:value => value))
        encrypted_value = [encrypted_value].pack(options[:encode]) if options[:encode]
        encrypted_value
      else
        value
      end
    end

    protected

    def attribute_method_already_implemented?(method_name)
      method_defined?(method_name) || private_method_defined?(method_name)
    end

    private

    # Forwards calls to :encrypt_#{attribute} or :decrypt_#{attribute} to the corresponding encrypt or decrypt method
    # if attribute was configured with attr_encrypted
    #
    # Example
    #
    #   class User
    #     attr_encrypted :email, :key => 'my secret key'
    #   end
    #
    #   User.encrypt_email('SOME_ENCRYPTED_EMAIL_STRING')
    def method_missing(method, *arguments, &block)
      if method.to_s =~ /^((en|de)crypt)_(.+)$/ && attr_encrypted?($3)
        send($1, $3, *arguments)
      else
        super
      end
    end

    def inherited(subclass)
      super
      subclass.attr_encrypted_options = attr_encrypted_options.dup
      subclass.encrypted_attributes = encrypted_attributes.dup
    end
  end

  # Decrypts a value for the attribute specified using options evaluated in the current object's scope
  #
  # Example
  #
  #  class User
  #    attr_accessor :secret_key
  #    attr_encrypted :email, :key => :secret_key
  #
  #    def initialize(secret_key)
  #      self.secret_key = secret_key
  #    end
  #  end
  #
  #  @user = User.new('some-secret-key')
  #  @user.decrypt(:email, 'SOME_ENCRYPTED_EMAIL_STRING')
  def decrypt(attribute, encrypted_value)
    self.class.decrypt(attribute, encrypted_value, evaluated_attr_encrypted_options_for(attribute))
  end

  # Encrypts a value for the attribute specified using options evaluated in the current object's scope
  #
  # Example
  #
  #  class User
  #    attr_accessor :secret_key
  #    attr_encrypted :email, :key => :secret_key
  #
  #    def initialize(secret_key)
  #      self.secret_key = secret_key
  #    end
  #  end
  #
  #  @user = User.new('some-secret-key')
  #  @user.encrypt(:email, 'test@example.com')
  def encrypt(attribute, value)
    self.class.encrypt(attribute, value, evaluated_attr_encrypted_options_for(attribute))
  end

  protected

  # Returns attr_encrypted options evaluated in the current object's scope for the attribute specified
  def evaluated_attr_encrypted_options_for(attribute)
    if evaluate_attr_encrypted_option(self.class.encrypted_attributes[attribute.to_sym][:mode]) == :per_attribute_iv_and_salt
      load_iv_for_attribute(attribute, self.class.encrypted_attributes[attribute.to_sym][:algorithm])
      load_salt_for_attribute(attribute)
    end

    self.class.encrypted_attributes[attribute.to_sym].inject({}) { |hash, (option, value)| hash[option] = evaluate_attr_encrypted_option(value); hash }
  end

  # Evaluates symbol (method reference) or proc (responds to call) options
  #
  # If the option is not a symbol or proc then the original option is returned
  def evaluate_attr_encrypted_option(option)
    if option.is_a?(Symbol) && respond_to?(option)
      send(option)
    elsif option.respond_to?(:call)
      option.call(self)
    else
      option
    end
  end

  def load_iv_for_attribute(attribute, algorithm)
    encrypted_attribute_name = self.class.encrypted_attributes[attribute.to_sym][:attribute]
    iv = send(:"#{encrypted_attribute_name}_iv")
    if iv.nil?
      begin
        algorithm ||= "aes-256-cbc"
        algo = OpenSSL::Cipher::Cipher.new(algorithm)
        iv = [algo.random_iv].pack("m")
        send(:"#{encrypted_attribute_name}_iv=", iv)
      rescue RuntimeError
      end
    end
    self.class.encrypted_attributes[attribute.to_sym][:iv] = iv.unpack("m").first if iv.present?
  end

  def load_salt_for_attribute(attribute)
    encrypted_attribute_name = self.class.encrypted_attributes[attribute.to_sym][:attribute]
    salt = send(:"#{encrypted_attribute_name}_salt") || send(:"#{encrypted_attribute_name}_salt=", Digest::SHA256.hexdigest((Time.now.to_i * rand(1000)).to_s)[0..15])
    self.class.encrypted_attributes[attribute.to_sym][:salt] = salt
  end
end