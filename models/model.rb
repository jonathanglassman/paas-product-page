
# boolean type
module Boolean; end
class TrueClass; include Boolean; end
class FalseClass; include Boolean; end

# Model is a base class for modeling and validating data
class Model

	@fields = {}

	# field is a helper for declaring what fields are valid for the resource
	def self.field(name, type, **opts)
		opts[:type] = type
		@fields ||= {}
		@fields[name] = opts
		define_method("#{name}") do
			if type == Boolean
				!!@values[name]
			else
				@values[name]
			end
		end
		define_method("#{name}=") do |value|
			if type == Boolean
				@values[name] = !!value
			else
				@values[name] = value
			end
		end
	end

	# fields returns all the field definitions set for the resource
	def self.fields
		parent_fields = superclass.respond_to?(:fields) ? superclass.fields : {}
		parent_fields.merge(@fields)
	end

	def self.has_field?(name)
		fields.each do |k,v|
			if k.to_s == name.to_s
				return true
			end
		end
		false
	end

	# create an instance of the resource. field values can be passed as kwargs or hash
	def initialize(vargs = {}, **kwargs)
		values = vargs.merge(kwargs).inject({}) do |args, (name, value)|
			if !self.class.has_field?(name)
				raise ArgumentError, "#{self.class.name} does not have a field called '#{name}'"
			end
			args[name.to_sym] = value
			args
		end
		@validated = false
		@values = {}
		self.class.fields.each do |name, opts|
			if values.has_key?(name)
				send("#{name.to_s}=", values[name])
			elsif values.has_key?(name.to_s)
				send("#{name.to_s}=", values[name])
			end
		end
	end

	# values returns any currently set field values
	def values
		self.class.fields.inject({}) do |values, (name, _opts)|
			values[name] = @values[name] if @values.has_key? name
			values
		end
	end

	# valid? returns false if any of the fields contain invalid data
	def valid?
		errors.size == 0
	end

	# returns true if validate has been called
	def validated?
		return !!@validated
	end

	# errors returns a hash of errors {:field_name => [err1, err2]}
	def errors
		validate.inject({}) do |h, err|
			k = err[:name]
			h[k] ||= []
			h[k] << "#{err[:label]} #{err[:message]}"
			h
		end
	end

	protected

	# validate returns a list of validation errors.
	def validate
		@validated = true
		self.class.fields.inject([]) do |errs, (name, opts)|
			if @values.has_key?(name)
				value = @values[name]
				msg = nil
				if !value.kind_of? opts[:type]
					msg = "must be of type #{opts[:type]} not #{value.class.name}"
				elsif opts[:type] == String
					if opts[:required] && (!value || value.strip.size == 0)
						msg = "cannot be blank"
					elsif opts.has_key?(:min) and value.size < opts[:min]
						msg = "is too short"
					elsif opts.has_key?(:max) and value.size > opts[:max]
						msg = "is too long"
					elsif opts.has_key?(:match) and !opts[:match].match?(value)
						msg = "is not valid"
					end
				elsif opts[:type] == Array
					if opts[:of] < Model
						err = value.map{|v| v.validate.first}.reject{|e| !e}.first
						errs.push({name: name, message: "#{err[:name].to_s.gsub(/_/,' ')}: #{err[:message]}"}) if err
					elsif opts[:of]
						if !value.all?{|v| v.kind_of?(opts[:of]) }
							msg = "must only contain #{opts[:of]} elements"
						end
					end
				else
					if opts.has_key?(:min) and value < opts[:min]
						msg = "must be at least #{opts[:min]}"
					elsif opts.has_key?(:max) and value > opts[:max]
						msg = "must be at most #{opts[:max]}"
					end
				end
				errs.push({name: name, message: msg, label: opts[:label] || name}) if !msg.nil?
			else
				errs.push({name: name, message: 'required'}) if opts[:required]
			end
			errs
		end
	end

end
