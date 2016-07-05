# Removes `nil` valued keys from nested `Hash`es.
module CarrotRpc::Scrub
  # Removes `nil` values as JSONAPI spec expects unset keys not to be transmitted
  def self.error(error)
    error.reject { |_, value|
      value.nil?
    }
  end

  # Removes `nil` values as JSONAPI spec expects unset keys not to be transmitted
  def self.errors(errors)
    errors.map { |error|
      error(error)
    }
  end
end
