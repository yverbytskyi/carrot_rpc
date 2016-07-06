# Used to format keys
module CarrotRpc::Format
  using CarrotRpc::HashExtensions

  # Logic to process the renaming of keys in a hash.
  # @param format [Symbol] :dasherize changes keys that have "_" to "-"
  # @param format [Symbol] :underscore changes keys that have "-" to "_"
  # @param format [Symbol] :skip, will not rename the keys
  # @param data [Hash] data structure to be transformed
  # @return [Hash] the transformed data
  def self.keys(format, data)
    case format
    when :dasherize
      data.rename_keys("_", "-")
    when :underscore
      data.rename_keys("-", "_")
    when :none
      data
    else
      data
    end
  end
end
